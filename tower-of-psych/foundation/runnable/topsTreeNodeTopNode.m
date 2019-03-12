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
         'abort',       false, ...  % abort experiment
         'pause',       false, ...  % pause experiment
         'skip',        false, ...  % skip to next task
         'calibrate',   []);        % calibrate given object (I know, not a flag)
      
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
      %  name ... string name of the top node
      function self = topsTreeNodeTopNode(varargin)
         
         % Make it
         self = self@topsTreeNode(varargin{:});
         
         % ---- Set up default filename
         %
         %  Default filename is based on the clock
         %  Can override simply by setting to new value
         %  Set to empty matrix to turn off data storage
         [path, name] = topsTreeNodeTopNode.getFilepath(self.name);
         self.filename = fullfile(path, name);
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
      %  Arguments (requred):
      %     constructor    ... string name of helper constructor
      %     doRecording    ... flag to start/stop recording automatically
      %     doCalibration  ... flag to automatically do calibration at start
      %     doShow         ... flag to show output (usu. eye position)
      %                             after calibration
      %     varargin       ... arguments to helper constructor
      function theHelper = addReadable(self, constructor, ...
            doRecording, doCalibration, doShow, varargin)

         % add the helper, with optional args
         theHelper = self.addHelpers(constructor, varargin{:});
         theObject = theHelper.(varargin{1}).theObject;

         % START CALLS
         %
         % Calibrate
         if doCalibration
            self.addCall('start', {@calibrate}, 'calibrate',  theObject);
         end
            
         % Show calibration
         if doShow
            self.addCall('start', {@calibrate, 's'}, 'show',  theObject);
         end
   
         % Turn on data recordings
         if doRecording
            self.addCall('start',  {@record, true}, 'record on',  theObject);
         end
            
         % FINISH CALLS
         %
         % Always close the device when finished
         self.addCall('finish', {@close}, 'close', theObject);
         
         % Turn of data recordings
         if doRecording
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
               pathstr = fileparts(self.filename);               
               if ~isempty(pathstr) && ~exist(pathstr, 'dir')
                  mkdir(pathstr);
               end

               % Write it to "filename" for the first time; later calls
               %  don't need to keep track of filename
               topsDataLog.writeDataFile(self.filename);
               
               % bind to dotsReadable helpers
               for ff = fieldnames(self.helpers)'
                  if isa(self.helpers.(ff{:}).theObject, 'dotsReadable')
                     [readerPath, readerFile] = ...
                        topsTreeNodeTopNode.getReadableFilename( ...
                        self.filename, self.name, self.helpers.(ff{:}).theObject);
                     self.helpers.(ff{:}).theObject.filepath = readerPath;
                     self.helpers.(ff{:}).theObject.filename = readerFile;
                  end
               end
            end
            
            % Seed random-number generator
            if self.randSeed
               rng('shuffle');
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
            if ~isempty(self.closingMessage) && isfield(self.helpers, 'feedback');
               self.helpers.feedback.show('text', self.closingMessage);
            end
            
            % Stop the runnable
            self.finish@topsRunnable();
            
            % Save self and always write data log to file
            if ~isempty(self.filename)
               
               % save self, without the gui handles
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
         while self.controlFlags.pause && ~self.controlFlags.abort
            pause(0.01);
         end
         
         % Abort experiment
         if self.controlFlags.abort
            self.controlFlags.abort=false;
            self.abort();
            ret = 1;
            return
         end
         
         % Recalibrate
         if ~isempty(self.controlFlags.calibrate)
            calibrate(self.controlFlags.calibrate);
            self.controlFlags.calibrate = [];
         end
         
         % Skip to next task
         if self.controlFlags.skip
            self.controlFlags.skip=false;
            child.abort();
            ret = 1;
            return
         end
      end
   end
   
   methods (Static)
      
      %% getFilepath
      %
      % Standard pathname for data 
      %
      %  studyTag   ... string name identifying the study
      %  sessionTag ... string name identifying the session
      function [pathname, filename] = getFilepath(studyTag, sessionTag)
         
         % Default session
         if nargin < 1 || isempty(studyTag)
            studyTag = 'test';
         end
         
         % Default filename is current time (to the second)
         if nargin < 2 || isempty(sessionTag)
            c = clock;
            sessionTag = sprintf('%.4d_%02d_%02d_%02d_%02d', ...
               c(1), c(2), c(3), c(4), c(5));
         end
         
         % Get the pathname
         pathname = fullfile( ...
            dotsTheMachineConfiguration.getDefaultValue('dataPath'), ...
            studyTag, 'raw', sessionTag);
         
         % Get the filename
         filename = [sessionTag '_topsDataLog.mat'];
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
      % studyTag is string name of the study
      % fileTag is string base name of the data file(s)
      %
      % Created 5/26/18 by jig
      %
      function [topNode, FIRA] = loadRawData(studyTag, fileTag)         

         %% Parse studyTag, fileTag
         %
         % Give defaults for debugging
         if nargin < 1
            studyTag = 'DBSStudy';
         end
         
         if nargin < 2 || isempty(fileTag)
            fileTag = '2019_01_13_10_03'; %'2018_11_20_15_20';
         end
         
         % get pathname of of the datafiles
         [datapath, filename] = topsTreeNodeTopNode.getFilepath(studyTag, fileTag);
         
         % Clear the data log
         topsDataLog.theDataLog(true);
         
         %% Get the ecode matrix using the topsDataLog utility
         %
         % get the mainTreeNode
         mainTreeNodeStruct = topsDataLog.getTaggedData('mainTreeNode', ...
            fullfile(datapath, filename));
         topNode = mainTreeNodeStruct.item;
         
         % Now read the ecodes -- note that this works only if the trial 
         %  struct was made with SCALAR entries only
         FIRA.ecodes = topsDataLog.parseEcodes('trial');
         
         %% Get the readable-specific data
         %
         D = dir([fullfile(datapath, fileTag) '_*']);
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
            
            % Call the dotsReadable static loadDateFile method            
            FIRA.(helperType) = feval([helperClass '.loadRawData'], ...
               fullfile(datapath, ff{:}), FIRA.ecodes, helper);
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
