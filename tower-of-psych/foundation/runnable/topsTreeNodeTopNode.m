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
   %  addSharedDrawables
   %  addSharedReadables
   %  addSharedPlayables
   %
   % Created 7/24/18 by jig
   
   properties (SetObservable)
      
      % files/directories for storing data
      dataFiles = struct( ...
         'filename',          [],               ... % Data filename with path
         'rawDirectory',      'topsDataLog',    ... % Subdirectory for raw files
         'readableDirectory', 'dotsReadable');      % Subdirectory for readable files
      
      % Flags for on-line flow control (used by run GUI)
      controlFlags = struct( ...
         'abort',       false, ...  % abort experiment
         'pause',       false, ...  % pause experiment
         'skip',        false, ...  % skip to next task
         'calibrate',   []);        % calibrate given object (I know, not a flag)
      
      % Structure of properties shared with other (task) nodes
      sharedHelpers = struct( ...
         'screenEnsemble',    [], ...
         'drawables',         {{}}, ...
         'readables',         {{}}, ...
         'playables',         {{}});
      
      % Flag to re-seed random number generator
      randSeed = true;
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
         
         % ---- Create topsCallLists for start/finish fevalables
         %
         % These can be filled in by various configuration
         %  subroutines so we don't need to know where what has and has not been
         %  added/configured.
         startCallList = topsCallList();
         startCallList.alwaysRunning = false;
         
         % NOTE that the finishFevalables will run in reverse order!!!!!
         finishCallList = topsCallList();
         finishCallList.alwaysRunning = false;
         finishCallList.invertOrder = true;
         
         % ---- Set up the main tree node
         %
         % We set this up here because we might have multiple task configuration
         % files (see below) that each add chidren to it
         self.iterations = 1; % Go once through the set of tasks
         self.startFevalable = {@run, startCallList};
         self.finishFevalable = {@run, finishCallList};
         
         % ---- Set up default filename
         %
         %  Default filename is based on the clock
         %  Can override simply by setting to new value
         %  Set to empty matrix to turn off data storage
         c = clock;
         self.dataFiles.filename = fullfile( ...
            dotsTheMachineConfiguration.getDefaultValue('dataPath'), ...
            self.name, self.dataFiles.rawDirectory, ...
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
      
      %% Utility: add shared drawables
      %
      % Add the screen ensemble and possibly other drawables used across
      % tasks
      %
      %  displayIndex   ...   used by dotsTheScreen
      %  remoteDrawing  ...   flag
      %  drawableList   ...   string or cell array of strings of
      %                             dotsDrawable class names
      %  makeEnsemble   ...   flag to make an ensemble (true) or just a
      %                             cell array of objects
      %
      function addSharedDrawables(self, displayIndex, remoteDrawing, ...
            drawableList, drawableListSettings, makeEnsemble, addFinalMessage)
         
         % Check args
         if nargin < 2 || isempty(displayIndex)
            displayIndex = 0;
         end
         
         if nargin < 2 || isempty(remoteDrawing)
            remoteDrawing = false;
         end
         
         % Check for drawables
         if isempty(displayIndex) || displayIndex < 0
            return
         end
         
         % Make the screen ensemble
         self.sharedHelpers.screenEnsemble = ...
            dotsTheScreen.makeEnsemble(remoteDrawing, displayIndex);
         
         % Add screen start/finish fevalables to the main topsTreeNode
         self.addCall('start', {@callObjectMethod, ...
            self.sharedHelpers.screenEnsemble, @open}, 'openScreen');
         self.addCall('finish', {@callObjectMethod, ...
            self.sharedHelpers.screenEnsemble, @close}, 'closeScreen');
         
         % add shared drawables to a single ensemble
         %
         if nargin >= 4 && ~isempty(drawableList)
            
            % Check drawableListSettings
            if nargin < 5 || isempty(drawableListSettings)
               drawableListSettings = cell(size(drawableList));
            elseif ischar(drawableListSettings{1})
               drawableListSettings = repmat({drawableListSettings}, size(playableList));
            end
            
            % Make each drawable by name
            self.sharedHelpers.drawables = cell(1, length(drawableList));
            for ii = 1:length(drawableList)
               
               % Make the drawable
               drawable = eval(drawableList{ii});
               
               % Add settings
               for jj = 1:2:length(drawableListSettings{ii})
                  drawable.(drawableListSettings{ii}{jj}) = drawableListSettings{ii}{jj+1};
               end
               
               % Add to the shared list
               self.sharedHelpers.drawables{ii} = drawable;
            end
            
            % Conditionally make the ensemble (default = true)
            if nargin < 6 || makeEnsemble
               self.sharedHelpers.drawables = dotsDrawable.makeEnsemble( ...
                  'sharedEnsemble', self.sharedHelpers.drawables, ...
                  self.sharedHelpers.screenEnsemble, true);
               
               % possibly add final message
               if nargin >= 7 && addFinalMessage && ...
                     length(drawableList) >= 2 && ...
                     all(strcmp('dotsDrawableText', drawableList(1:2)))
                  
                  self.addCall('finish', {@dotsDrawableText.drawEnsemble, ...
                     self.sharedHelpers.drawables, ...
                     {'All done.' 'Thank you!'}, true, 2}, 'finalMessage');
               end
            end
         end
      end
      
      %% Utility: add shared readables
      %
      % Add the readables used across tasks
      %
      % readableList can be:
      %     - string name of class to use
      %     - cell array of string names of classes to use
      %  readableListSettings: TO DO - jig
      %  doCalibration: logical array of flags to calibrate each object
      %  doRecording: logical array of flags to record for each object
      
      function addSharedReadables(self, readableList, readableListSettings, ...
            doCalibration, doRecording)
         
         % ---- Check for readables
         %
         if nargin > 1 && ~isempty(readableList)
            
            if ~iscell(readableList)
               readableList = {readableList};
            end
            numReadables = length(readableList);
            
            % Check playableListSettings
            if nargin < 3 || isempty(readableListSettings)
               readableListSettings = cell(size(readableList));
            elseif ischar(readableListSettings{1})
               readableListSettings = repmat({readableListSettings}, size(playableList));
            end
            
            if nargin <= 4 || isempty(doCalibration)
               doCalibration = true(1,numReadables);
            elseif length(doCalibration) == 1 && numReadables > 1
               doCalibration = repmat(doCalibration, 1, numReadables);
            end
            
            if nargin <= 5 || isempty(doRecording)
               doRecording = true(1, numReadables);
            elseif length(doRecording) == 1 && numReadables > 1
               doRecording = repmat(doRecording, 1, numReadables);
            end
            
            self.sharedHelpers.readables = cell(size(readableList));
            for ii = 1:numReadables
               
               % Create the ui object
               ui = eval(readableList{ii});
               
               % Add settings
               for jj = 1:2:length(readableListSettings{ii})
                  ui.(readableListSettings{ii}{jj}) = readableListSettings{ii}{jj+1};
               end
               
               % Check if it needs the screen
               if any(strcmp(properties(ui), 'screenEnsemble'))
                  ui.screenEnsemble = self.sharedHelpers.screenEnsemble;
               end
               
               % Set up data recording
               if ~isempty(self.dataFiles.filename)
                  [path, name] = fileparts(self.dataFiles.filename);
                  ui.filepath = fullfile(path(1:find(path==filesep,1,'last')-1), self.dataFiles.readableDirectory);
                  ui.filename = sprintf('%s_%s', name, readableList{ii}(13:end));
               end
               
               % Save it
               self.sharedHelpers.readables{ii} = ui;
               
               % Add start/finish fevalables -- remember the finishes run
               % in reverse order
               if doCalibration(ii)
                  self.addCall('start',  {@calibrate, ui}, 'calibrate ui');
               end
               if doRecording(ii)
                  self.addCall('start',  {@record, ui, true}, 'start recording ui');
               end
               self.addCall('finish', {@close, ui}, 'close ui');
               if doRecording(ii)
                  self.addCall('finish', {@record, ui, false}, 'finish recording ui');
               end
            end
         end
      end
      
      %% Utility: add shared playables
      %
      % Add the playables used across tasks. For now only handles
      % playableFiles
      %
      % playableList can be:
      %     - string name of file to use
      %     - cell array of string names of files to use
      % playableListSettings: cell array of property/value pairs
      %  isBlocking: flag or logical array of flags
      function addSharedPlayables(self, playableList, playableListSettings)
         
         if nargin < 2 || isempty(playableList)
            return
         end
         
         % Check playableListSettings
         if nargin < 3 || isempty(playableListSettings)
            playableListSettings = cell(size(playableList));
         elseif ~iscell(playableListSettings{1})
            playableListSettings = repmat({playableListSettings}, size(playableList));
         end
         
         % Make the playables
         self.sharedHelpers.playables = cell(1, length(playableList));
         for ii = 1:length(playableList)
            
            % Make the playable
            if strncmp(playableList{ii}, 'dotsPlayable', length('dotsPlayable'))
               playable = feval(playableList{ii});
            else
               % use playableFile and input as filename
               playable = dotsPlayableFile();
               playable.fileName = playableList{ii};
            end
            
            % Add settings
            for jj = 1:2:length(playableListSettings{ii})
               playable.(playableListSettings{ii}{jj}) = playableListSettings{ii}{jj+1};
            end
            
            % Prepare to play
            playable.prepareToPlay();
            
            % Add to sharedHelpers
            self.sharedHelpers.playables{ii} = playable;
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
            self.GUIs.run.handle = feval(self.GUIs.run.name, self, self.sharedHelpers.readables{:});
         else
            
            % Start data logging
            if ~isempty(self.dataFiles.filename)
               
               % Flush the log
               topsDataLog.theDataLog(true);
               
               % Save a start time
               topsDataLog.logDataInGroup(mglGetSecs(), 'startTime');
               
               % Write it to "filename" for the first time; later calls
               %  don't need to keep track of filename
               topsDataLog.writeDataFile(self.dataFiles.filename);
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
            
            % Stop the runnable
            self.finish@topsRunnable();
            
            % Save self and always write data log to file
            if ~isempty(self.dataFiles.filename)
               
               % save self, without the gui handles
               warning('OFF', 'MATLAB:structOnObject');
               selfStruct = struct(self);
               selfStruct.GUIs.run.handle = [];
               selfStruct.GUIs.database.handle = [];
               topsDataLog.logDataInGroup(selfStruct, 'mainTreeNode');
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
      
      %% addCall
      %
      % Utility to easily add a call to the start/finish call list
      %
      % type is 'start' or 'finish' (default)
      % fevalable is a cell array that can be used as an argument to feval
      % name is a string name of the fevalable
      %
      function addCall(self, type, fevalable, name)
         
         % get the start/finish call list from the fevalable
         if strcmp(type, 'start')
            callList = self.startFevalable{2};
         else
            callList = self.finishFevalable{2};
         end
         
         % add the call
         addCall(callList, fevalable, name);
      end
   end
   
   methods (Static)
      
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
      function [topNode, FIRA] = getDataFromFile(filename, studyTag, refTime)
         
         %% Parse filename, studyTag
         %
         % Give defaults for debugging
         if nargin < 1 || isempty(filename)
            filename = 'data_2018_08_21_13_25';
         end
         
         if nargin < 2 || isempty(studyTag)
            studyTag = 'DBSStudy';
         end
         
         if nargin < 3 || isempty(refTime)
            refTime = 'time_screen_fixOn';
         end
         
         % Clear the data log
         topsDataLog.theDataLog(true);
         
         % Use the machine-specific data pathname to find the data
         [filepath, fname] = fileparts(filename);
         if nargin>=2 && ~isempty(studyTag)
            filepath = fullfile(dotsTheMachineConfiguration.getDefaultValue('dataPath'), studyTag);
            filewithpath = fullfile(filepath, 'topsDataLog',  [fname '.mat']);
         end
         
         %% Get the ecode matrix using the topsDataLog utility
         %
         % get the mainTreeNode
         mainTreeNodeStruct = topsDataLog.getTaggedData('mainTreeNode', filewithpath);
         topNode = mainTreeNodeStruct.item;
         
         % Now read the ecodes -- note that this works only if the trial struct was
         % made only with SCALAR entries
         FIRA.ecodes = topsDataLog.parseEcodes('trial');
         
         %% Synchronize timing
         %
         % use name prefixes to sync times relative to "trialStart" times
         %  for each time source (e.g., "local", "screen", "ui", etc).
         startInds = cell2num(strfind(FIRA.ecodes.name, 'trialStart'));
         roundTripInds = cell2num(strfind(FIRA.ecodes.name, 'roundTrip'));
         for ii = find(startInds>0)
            
            % Find the times from the same source
            Lmatch = cell2num(strfind(FIRA.ecodes.name, ...
               FIRA.ecodes.name{ii}(1:startInds(ii)-2)))>0 & roundTripInds==0;
            
            % Leave the raw trialStart times unchanged.
            Lmatch(ii) = false;
            
            % Subtract the start time
            FIRA.ecodes.data(:,Lmatch) = FIRA.ecodes.data(:,Lmatch) - ...
               repmat(FIRA.ecodes.data(:,ii),1,sum(Lmatch));
         end
         
         % Calibrate all times (except "trialStart" and "roundTrip") to ref time
         timeInds = cell2num(strfind(FIRA.ecodes.name, 'time_'))>0 & ...
            startInds==0 & roundTripInds==0;
         if any(timeInds)
            refInd = strcmp(FIRA.ecodes.name, refTime);
            timeInds(refInd) = false;
            FIRA.ecodes.data(:,timeInds) = FIRA.ecodes.data(:,timeInds) - ...
               repmat(FIRA.ecodes.data(:,refInd), 1, sum(timeInds));
         end
         
         %% Get the analog data
         %
         % Use constructor class static method to read the data file.
         if ~isempty(topNode.sharedHelpers.readables)
            
            % Get the readables file base name
            uiFile = fullfile(filepath, topNode.dataFiles.readableDirectory, fname);
            
            % Loop through the readables
            for ii = 1:length(topNode.sharedHelpers.readables)
               
               % Get the current readable
               ui = topNode.sharedHelpers.readables{ii};
               
               % For now just for eye data... will need to generalize this later
               if isa(ui, 'dotsReadableEye')
                  calibrationData = topsDataLog.getTaggedData('dotsReadableEye calibration');
               else
                  calibrationData = [];
               end
               
               % Get synch times
               tli = find(strcmp(FIRA.ecodes.name, 'time_local_trialStart'), 1);
               tui = find(strcmp(FIRA.ecodes.name, 'time_ui_trialStart'), 1);
               twi = find(strcmp(FIRA.ecodes.name, refTime), 1);
               
               % Call the class-specific method
               FIRA.analog = ui.readDataFromFile(uiFile, FIRA.ecodes.data(:,[tli tui twi]), ...
                  calibrationData);
            end
         end
      end
   end
end