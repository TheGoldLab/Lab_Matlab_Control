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
         c = clock;
         self.filename = fullfile( ...
            topsTreeNodeTopNode.getFilepath(self.name), ...
            sprintf('data_%.4d_%02d_%02d_%02d_%02d.mat', ...
            c(1), c(2), c(3), c(4), c(5)));
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
      %  studyTag  ... string name identifying the study (required)
      %  dataType  ... 'topsDataLog' (default) or 'readable'
      function pathname = getFilepath(studyTag, dataType)
         
         if nargin < 2 || isempty(dataType)
            dataType = 'topsDataLog';
         end
         
         pathname = fullfile( ...
            dotsTheMachineConfiguration.getDefaultValue('dataPath'), ...
            studyTag, dataType);
      end
      
      %% getReadableFilename
      %
      % Get path and file names for a readable given:
      %  filename    ... name of the associated topsDataLog file
      %  studyTag  ... string name identifying the study
      %  readable    ... the readable object
      function [readerPath, readerFile] = getReadableFilename(filename, studyTag, readable)
         
         % path
         readerPath = fullfile( ...
            dotsTheMachineConfiguration.getDefaultValue('dataPath'), ...
            studyTag, 'dotsReadable');
         
         % file has readable class suffix
         [~, name] = fileparts(filename);
         if isobject(readable)
            readable = class(readable);
         end
         K = strfind(readable, 'dotsReadable');
         if ~isempty(K)
            readable(K:K+length('dotsReadable')-1) = [];
         end
         readerFile = [name '_' readable];
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
      % studyTag is the name of the topsTreeNodeTopNode and data dir
      % refTime is the name of the column used as the reference time
      %
      % Created 5/26/18 by jig
      %
      function [topNode, FIRA] = getDataFromFile(filename, studyTag)
         
         %% Parse filename, studyTag
         %
         % Give defaults for debugging
         if nargin < 1 || isempty(filename)
            filename = 'data_2018_11_20_15_20';
         end
         
         if nargin < 2 || isempty(studyTag)
            studyTag = 'DBSStudy';
         end
         
         % Clear the data log
         topsDataLog.theDataLog(true);
         
         %% Get the ecode matrix using the topsDataLog utility
         %
         % get the mainTreeNode
         mainTreeNodeStruct = topsDataLog.getTaggedData('mainTreeNode', ...
            fullfile(topsTreeNodeTopNode.getFilepath(studyTag), filename));
         topNode = mainTreeNodeStruct.item;
         
         % Now read the ecodes -- note that this works only if the trial struct was
         % made with SCALAR entries only
         FIRA.ecodes = topsDataLog.parseEcodes('trial');
         
         %% Get the analog data
         %
         % Use constructor class static method to read the data file.
         helperNames = fieldnames(topNode.helpers)';
         for hh = helperNames(strncmp('dotsReadable', helperNames, length('dotsReadable')))
            
            % Get the readables file directory, base name
            [readerPath, readerFile] = ...
               topsTreeNodeTopNode.getReadableFilename(filename, studyTag, hh{:});
            
            % Call the class-specific method with the filename, 
            % synchronization data, and calibration data
            FIRA.analog.(hh{:}) = topNode.helpers.(hh{:}).theObject.readDataFromFile( ...
               fullfile(readerPath, readerFile), ...
               topsDataLog.getTaggedData(['synchronize ' hh{:}]), ...
               topsDataLog.getTaggedData(['calibrate ' hh{:}]));
         end
      end
   end
end