classdef topsTreeNodeTopNode < topsTreeNode
   % Class topsTreeNodeTopNode
   %
   %  Special sub-class of topsTreeNode intended to be at the top level of
   % a tree-like structure that runs all of its children as an experiment.
   %
   %  Unlike other topsTreeNodes because it has guis and other helper
   % objects associated with it.
   %
   %  After creating, use these methods to extend functionality (see below
   %  for details):
   %
   %  addGUIs
   %  addDrawables
   %  addHelpers (see topsTreeNode)
   %
   % Created 7/24/18 by jig
   
   properties (SetObservable)
      
      % Data filename with path
      filename;
      
      % Flags for on-line flow control (used by run GUI)
      controlFlags = struct( ...
         'abort',          struct( ...    % abort experiment
         'flag',           false, ...  
         'key',            'KeyboardQ'), ...
         'pause',          struct( ...    % pause experiment
         'flag',           false, ...  
         'key',            'KeyboardP'), ...
         'taskStart',      struct( ...    % task start
         'flag',           false, ...  
         'key',            'KeyboardT'), ...
         'skip',           struct( ...    % skip to next task
         'flag',           false, ...  
         'key',            'KeyboardS'), ...
         'calibrate',      struct( ...    % calibrate given object (I know, not a flag)
         'flag',           [], ...     
         'key',            'KeyboardC'));
      
      % Flag to re-seed random number generator
      randSeed = true;
      
      % Closing message
      closingMessage = 'All done. Thank you!';
   end
   
   properties (Hidden)
      
      % GUIs
      GUIs = struct( ...
         'database',    struct('name', [], 'handle', []), ...
         'run',         struct('name', [], 'handle', []));
      
      % silly flag to avoid errors with GUI startup
      isStarted = false;
   end
   
   methods
      
      %% Constructor method
      %
      % Constuct with optional argument:
      %  name                 ... string name of the top node
      %  filename             ... string name of file (with path)
      %  addControlKeyboard   ... flag to add control keyboard <default true>
      function self = topsTreeNodeTopNode(name, filename, addControlKeyboard)
         
         % ---- Make it using given or default filename
         %
         if nargin < 1 || isempty(name)
            name = 'topNode';
         end
         self = self@topsTreeNode(name);
         
         % ---- Set up default filename
         %
         %  Default filename is based on the clock
         %  Can override simply by setting to new value
         %  Set to empty matrix to turn off data storage
         if nargin < 2 || isempty(filename)
            [path, name] = topsTreeNodeTopNode.getFileparts(self.name);
            self.filename = fullfile(path, name);
         end
         
         % ---- Possibly add control keyboard
         %
         if nargin < 3 || addControlKeyboard
            
            % Make start function that defines events
            startStruct = struct('name', {}, 'component', {});
            index = 1;
            for ff = fieldnames(self.controlFlags)'
               startStruct(index).name = ff{:};
               startStruct(index).component = self.controlFlags.(ff{:}).key;
               index = index + 1;
            end
            
            % Add a keyboard, definining events based on the control flags
            self.addHelpers('readable', ...
               'name',        'controlKeyboard', ...
               'fevalable',   {@dotsReadableHIDKeyboard, 2}, ...
               'start',       {@defineEventsFromStruct startStruct 'control'});
         end
      end
      
      %% Utility: add GUIs
      %
      %
      function addGUIs(self, varargin)
         
         % varargin is GUI type/name pairs
         for ii=1:2:nargin-1
            self.GUIs.(varargin{ii}).name = varargin{ii+1};
         end
      end
      
      %% Add readable, with initialization/cleanup
      %
      %  Arguments (required):
      %     readableName   ... string name of the readable to use
      %  Parameters (optional):
      %     doRecording    ... flag to start/stop recording automatically
      %     doCalibration  ... flag to automatically do calibration at start
      %     doShow         ... flag to show output (usu. eye position)
      %                             after calibration
      %     varargin       ... arguments to helper constructor
      function theHelper = addReadable(self, readableName, varargin)
         
         % Parse the arguments
         [parsedArgs, passedArgs] = parseHelperArgs(readableName, varargin, ...
            'doRecording',       false,    ...
            'doCalibration',     false,   ...
            'doShow',            false);
         
         % add the helper, with optional args
         theHelper = self.addHelpers('readable', passedArgs{:});
         theObject = theHelper.(readableName).theObject;
         
         % START CALLS
         %
         % Calibrate
         if parsedArgs.doCalibration
            self.addCall('start', {@calibrate}, 'calibrate',  theObject);
         end
         
         % Show calibration
         if parsedArgs.doShow
            self.addCall('start', {@calibrate, 's'}, 'show',  theObject);
         end
         
         % Turn on data recordings
         if parsedArgs.doRecording
            self.addCall('start',  {@record, true}, 'record on',  theObject);
         end
         
         % FINISH CALLS
         %
         % Always close the device when finished
         self.addCall('finish', {@close}, 'close', theObject);
         
         % Turn of data recordings
         if parsedArgs.doRecording
            self.addCall('finish', {@record, false}, 'record off', theObject);
         end
      end
      
      %% Start
      %
      % Overloaded start function, which checks for gui(s) and sets up the
      % topsDataLog
      %
      function start(self)
         
         % start databaseGUI
         if ~isempty(self.GUIs.database.name) && isempty(self.GUIs.database.handle)
            self.GUIs.database.handle = feval(self.GUIs.database.name);
         end
         
         % start runGUI
         if ~isempty(self.GUIs.run.name) && isempty(self.GUIs.run.handle)
            
            % check for dotsReadableEye to send
            readableEye = [];
            helper = self.getHelperByClassName('dotsReadableEye');
            if ~isempty(helper)
               readableEye = helper.theObject;
            end
            
            % Call the gui constructor
            self.GUIs.run.handle = feval(self.GUIs.run.name, self, readableEye);
            
         else
            
            % Start data logging
            if ~isempty(self.filename)
               
               % Flush the log
               topsDataLog.theDataLog(true);
               
               % Save a start time
               topsDataLog.logDataInGroup(mglGetSecs(), 'startTime');
               
               % Make sure the file directory exists
               filepath = fileparts(self.filename);
               if ~isempty(filepath) && ~exist(filepath, 'dir')
                  mkdir(filepath);
               end
               
               % Write it to "filename" for the first time; later calls
               %  don't need to keep track of filename
               topsDataLog.writeDataFile(self.filename);
               
               % bind to dotsReadable helpers. First get the file prefix
               sessionTag = [fileparts(filepath) '_'];
               for ff = fieldnames(self.helpers)'
                  
                  % Check that the helper is a dotsReadable object
                  if isa(self.helpers.(ff{:}).theObject, 'dotsReadable')
                     
                     % Parse the filename from the readable class
                     className = parseSnowDotsClassName( ...
                        class(self.helpers.(ff{:}).theObject), ...
                        'dotsReadable');
                     
                     % Set it in the helper object
                     self.helpers.(ff{:}).theObject.filepath = filepath;
                     self.helpers.(ff{:}).theObject.filename = [sessionTag className];
                  end
               end
            end
            
            % Seed random-number generator
            if self.randSeed
               rng('shuffle');
            end
            
            % Set the task indices
            for ii = 1:length(self.children)
               if isa(self.children{ii}, 'topsTreeNodeTask')
                  self.children{ii}.taskIndex = ii;
               end
            end
               
            % Run for realsies
            self.start@topsRunnable();
            
            % Set silly flag
            self.isStarted = true;
         end
      end
      
      %% Finish
      %
      % Overloaded finish function, needed because we might have started
      %  GUI but did not run anything
      %
      function finish(self)
         
         % This is needed because it might have been started in the gui
         if self.isStarted
            
            % Show the final message
            if ~isempty(self.closingMessage)
               topsTaskHelperMessage.showTextMessage(self.closingMessage, 'duration', 3);
            end
            
            % Stop the runnable
            self.finish@topsRunnable();
            
            % Save self and always write data log to file
            if ~isempty(self.filename)
               
               % save self, without the gui handlesfeval(self.clockFunction);
               warning('OFF', 'MATLAB:structOnObject');
               self.GUIs = [];
               topsDataLog.logDataInGroup(struct(self), 'mainTreeNode');
               topsDataLog.writeDataFile();
            end
         end
      end
      
      %% updateGUI
      %
      % Does GUI need updating?
      function updateGUI(self, name, varargin)
         
         if ~isempty(self.GUIs.run.handle)
            
            feval(self.GUIs.run.name, [self.GUIs.run.name name], ...
               self.GUIs.run.handle, [], guidata(self.GUIs.run.handle), varargin{:});
         end
      end
      
      %% checkFlags
      %
      % Check status flags, which might be set by the GUI.
      %  Return ~0 if something happened
      %
      function ret = checkFlags(self, child)
         
         % Default return value
         ret = 0;
         
         % Possibly check gui
         if ~isempty(self.GUIs.run.handle)
            drawnow;
         end
         
         % Pause experiment, wait for ui
         while self.controlFlags.pause.flag && ~self.controlFlags.abort.flag
            pause(0.01);
         end
         
         % Abort experiment
         if self.controlFlags.abort.flag
            self.controlFlags.abort.flag=false;
            self.abort();
            ret = 1;
            return
         end
         
         % Recalibrate
         if ~isempty(self.controlFlags.calibrate.flag)
            calibrate(self.controlFlags.calibrate.flag);
            self.controlFlags.calibrate.flag = [];
         end
         
         % Skip to next task
         if self.controlFlags.skip.flag
            self.controlFlags.skip.flag=false;
            child.abort();
            ret = 1;
            return
         end
      end
   end
   
   methods (Static)
      
      %% getFileparts
      %
      % Standard pathname for data
      %
      %  studyTag   ... string name identifying the study
      %  sessionTag ... string name identifying the session
      %  dataTag    ... string suffix for data file
      function [pathname, filename] = getFileparts(studyTag, sessionTag, dataTag)
         
         % Default session
         if nargin < 1 || isempty(studyTag)
            studyTag = 'test';
         end
         
         % Default sessionTag is current time (to the second)
         if nargin < 2 || isempty(sessionTag)
            c = clock;
            sessionTag = sprintf('%.4d_%02d_%02d_%02d_%02d', ...
               c(1), c(2), c(3), c(4), c(5));
         end
         
         % Default dataTag
         if nargin < 3 || isempty(dataTag)
            dataTag = '_topsDataLog.mat';
         end
         
         % Get the pathname
         pathname = fullfile( ...
            dotsTheMachineConfiguration.getDefaultValue('dataPath'), ...
            studyTag, 'raw', sessionTag);
         
         % Get the filename
         filename = [sessionTag dataTag];
      end
      
      %% getDataFromFile
      %
      % Utility for making FIRA from a standard data file created by an
      % experiment run using a topsTreeNodeTopNode
      %
      % Calls topsDataLog.parseEcodes, which assumes that the tag 'trial' corresponds
      %  to a trial data structure in the topsDataLog.
      % Also calls dotsReadable.readDataFromFile using the given ui
      %
      % studyTag   ... string name identifying the study
      % sessionTag ... string name identifying the session
      %
      % Created 5/26/18 by jig
      %
      function [topNode, FIRA] = loadRawData(studyTag, sessionTag)
         
         %% Parse studyTag, fileTag
         %
         % Give defaults for debugging
         if nargin < 1
            studyTag = 'DBSStudy';
         end
         
         if nargin < 2 || isempty(sessionTag)
            sessionTag = '2019_01_13_10_03'; %'2018_11_20_15_20';
         end
         
         % get pathname of of the datafiles
         [pathname, filename] = topsTreeNodeTopNode.getFileparts(studyTag, sessionTag);
         
         % Clear the data log
         topsDataLog.theDataLog(true);
         
         %% Get the ecode matrix using the topsDataLog utility
         %
         % get the mainTreeNode
         mainTreeNodeStruct = topsDataLog.getTaggedData('mainTreeNode', ...
            fullfile(pathname, filename));
         topNode = mainTreeNodeStruct.item;
         
         % Now read the ecodes -- note that this works only if the trial
         %  struct was made with SCALAR entries only
         FIRA.ecodes = topsDataLog.parseEcodes('trial');
         
         %% Get the readable-specific data
         %
         [~, sessionTag] = fileparts(pathname);
         D = dir([fullfile(pathname, sessionTag) '_*']);
         for ff = setdiff({D.name}, filename)
            
            % Save as field named after readable subclass
            [~,name] = fileparts(ff{:});
            helperType = name(find(name=='_',1,'last')+1:end);
            
            % Get helper class
            helperClass = ['dotsReadable' helperType];
            
            % Get the helper
            if strcmp(helperType, 'Spike2')
               helper = topNode.helpers.dotsReadableEyeEOG.theObject;
            else
               helper = topNode.helpers.(helperType).theObject;
            end
            
            % Call the dotsReadable static loadDataFile method
            FIRA.(helperType) = feval([helperClass '.loadRawData'], ...
               fullfile(pathname, ff{:}), FIRA.ecodes, helper);
         end
         
         % Look for readableEye data
         helpers = fieldnames(FIRA);
         eyei = find(strncmp('Eye', helpers, length('Eye')),1);
         if ~isempty(eyei)
            FIRA.analog = FIRA.(helpers{eyei});
            FIRA = rmfield(FIRA, helpers{eyei});
         end
         
         % Look for spike2 data
         if any(strcmp('Spike2', helpers))
            FIRA.analog = FIRA.Spike2.analog;
            FIRA.spikes = FIRA.Spike2.spikes;
         end
      end
   end
end
