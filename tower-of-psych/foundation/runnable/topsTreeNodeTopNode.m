classdef topsTreeNodeTopNode < topsTreeNode
   % Class topsTreeNodeTopNode
   %
   %  Special sub-class of topsTreeNode intended to be at the top level of
   % a tree-like structure that runs all of its children as an experiment.
   %
   %  Unlike other topsTreeNodes because it has guis and other helper
   % objects associated with it
   %
   % Created 7/24/18 by jig
   
   properties (SetObservable)
      
      % Data filename with path
      filename;
      
      % subdirectory for raw files
      rawDirectory = 'topsDataLog';
      
      % subdirectory for readable files
      readableDirectory = 'dotsReadable';

      % Abort experiment
      abortFlag=false;
      
      % Pause experiment
      pauseFlag=false;
      
      % Skip to next task
      skipFlag=false;
      
      % Recalibrate
      calibrateObject;
      
      % Run GUI name or fevalable
      runGUIname;
      
      % DatabaseGUI name
      databaseGUIname;
      
      % For TTL pulses -- the object
      TTLdOutObject;
      
      % For TTL pulses -- the channel
      TTLchannel;
      
      % For TTL pulses -- pause between pulses
      TTLpauseTime;
      
      % Structure of properties shared with other (task) nodes
      sharedProperties = struct( ...
         'screenEnsemble',    [], ...
         'textEnsemble',      [], ...
         'readableList',      [], ...
         'playableList',      [], ...
         'sendTTLs',          []);
   end
   
   properties (Hidden)
      
      % handle to taskGui interface
      runGUIHandle = [];
      
      % databaseGUI name
      databaseGUIHandle = [];
      
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
         self.filename = fullfile( ...
            dotsTheMachineConfiguration.getDefaultValue('dataPath'), ...
            self.name, self.rawDirectory, ...
            sprintf('data_%.4d_%02d_%02d_%02d_%02d.mat', ...
            c(1), c(2), c(3), c(4), c(5)));
      end
      
      %% Utility: add default drawables
      %
      % Add the screen ensemble and possibly other drawables used across
      % tasks
      %
      function addDrawables(self, displayIndex, remoteDrawing, addTextEnsemble)
         
         % ---- Check for drawables
         %
         if displayIndex >= 0
            
            % Make the screen ensemble
            self.sharedProperties.screenEnsemble = ...
               dotsTheScreen.makeEnsemble(remoteDrawing, displayIndex);
            
            % Add screen start/finish fevalables to the main topsTreeNode
            self.addCall('start', {@callObjectMethod, ...
               self.sharedProperties.screenEnsemble, @open}, 'openScreen');
            self.addCall('finish', {@callObjectMethod, ...
               self.sharedProperties.screenEnsemble, @close}, 'closeScreen');
            
            % Possibly make a text ensemble for showing messages
            %
            % NOTE that for now it only makes the ensemble with 2 objects
            if nargin > 3 && addTextEnsemble
               
               % Make the ensemble
               self.sharedProperties.textEnsemble = ...
                  dotsDrawableText.makeEnsemble('text', 2, ...
                  [], self.sharedProperties.screenEnsemble);
               
               % Add a final message
               self.addCall('finish', {@dotsDrawableText.drawEnsemble, ...
                  self.sharedProperties.textEnsemble, ...
                  {'All done.', 'Thank you!'}, 2, 0}, 'finalMessage');
            end
         end
      end
      
      %% Utility: add default readables
      %
      % Add the readables used across tasks
      %
      function addReadables(self, readableNames)
         
         % ---- Check for readables
         %
         if nargin > 1 && ~isempty(readableNames)
            
            if ~iscell(readableNames)
               readableNames = {readableNames};
            end
            
            self.sharedProperties.readableList = cell(size(readableNames));
            for ii = 1:length(readableNames)
               
               % Get and save the ui object
               ui = eval(readableNames{ii});
               self.sharedProperties.readableList{ii} = ui;
               
               % Check if it needs the screen
               if isfield(struct(ui), 'screenEnsemble')
                  ui.screenEnsemble = self.sharedProperties.screenEnsemble;
               end
               
               % Set up data recording
               if ~isempty(self.filename)
                  [path, name] = fileparts(self.filename);
                  ui.filepath = fullfile(path(1:find(path==filesep,1,'last')-1), self.readableDirectory);
                  ui.filename = sprintf('%s_%s', name, readableNames{ii}(13:end));
               end
               
               % Add start/finish fevalables -- remember the finishes run
               % in reverse order
               self.addCall('start',  {@calibrate, ui}, 'calibrate ui');
               self.addCall('start',  {@record, ui, true}, 'start recording ui');
               self.addCall('finish', {@close, ui}, 'close ui');
               self.addCall('finish', {@record, ui, false}, 'finish recording ui');
            end
         end
      end
      
      %% Start
      %
      % Overloaded start function, which checks for gui(s) and sets up the
      % topsDataLog
      %
      function start(self)
         
         % start databaseGUI
         if ~isempty(self.databaseGUIname) && isempty(self.databaseGUIHandle)
            self.databaseGUIHandle = feval(self.databaseGUIname);
         end
         
         % start runGUI
         if ~isempty(self.runGUIname) && isempty(self.runGUIHandle)
            self.runGUIHandle = feval(self.runGUIname, self, self.sharedProperties.readableList{:});
         else
            
            % Start data logging
            if ~isempty(self.filename)
               
               % Flush the log, log self, and save to the file
               topsDataLog.flushAllData(); % Flush stale data, just in case
               
               % save self, without the gui handles
               selfStruct = struct(self);
               selfStruct.runGUIHandle = [];
               selfStruct.databaseGUIHandle = [];
               topsDataLog.logDataInGroup(selfStruct, 'mainTreeNode');
               topsDataLog.writeDataFile(self.filename);
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
         
         if self.isStarted
            self.finish@topsRunnable();
         end
         
         % To be safe, always write data log to file
         if ~isempty(self.filename)
            topsDataLog.writeDataFile();
         end
      end
      
      %% updateGUI
      %
      % Does GUI need updating?
      function updateGUI(self, name, varargin)
         
         if ~isempty(self.runGUIHandle)
            
            feval(self.runGUIname, [self.runGUIname name], ...
               self.runGUIHandle, [], guidata(self.runGUIHandle), varargin{:});
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
         if ~isempty(self.runGUIHandle)
            drawnow;
         end
         
         % Pause experiment, wait for ui
         while self.pauseFlag && ~self.abortFlag
            pause(0.01);
         end
         
         % Abort experiment
         if self.abortFlag
            self.abortFlag=false;
            self.abort();
            ret = 1;
            return
         end
         
         % Recalibrate
         if ~isempty(self.calibrateObject)
            calibrate(self.calibrateObject);
            self.calibrateObject = [];
         end
         
         % Skip to next task
         if self.skipFlag
            self.skipFlag=false;
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
      
      %% sentTTLsequence
      %
      % function [startTime, finishTime, refTime] = sendTTLsequence(numPulses)
      %
      % Utility for sending a sequence of TTL pulses with standard parameters.
      % This way you only have to change it here.
      %
      function [startTime, finishTime, refTime] = sendTTLsequence(self, numPulses)
         
         if isempty(self.TTLdOutObject)
            self.TTLdOutObject = feval( ...
               dotsTheMachineConfiguration.getDefaultValue('dOutClassName'));
            self.TTLchannel   = 0;
            self.TTLpauseTime = 0.2;
         end           
         
         % Check argument
         if nargin < 1 || isempty(numPulses)
            numPulses = 1;
         end
         
         if numPulses < 1
            startTime  = [];
            finishTime = [];
            return
         end
         
         % Get time of first pulse
         [startTime, refTime] = self.TTLdOutObject.sendTTLPulse(self.TTLchannel);
         
         % get the remaining pulses and save the finish time
         finishTime = startTime;
         for pp = 1:numPulses-1
            pause(self.TTLpauseTime);
            finishTime = self.TTLdOutObject.sendTTLPulse(self.TTLchannel);
         end
      end
   end
   
   methods (Static)
      
      %% Utility for making FIRA from a standard data file created by an
      % experiment run using a topsTreeNodeTopNode
      %
      % Make a FIRA data struct from the raw/pupil data of a set of modular tasks
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
         
         % Flush the data log
         topsDataLog.flushAllData();
         
         % Use the machine-specific data pathname to find the data
         filepath = fullfile(dotsTheMachineConfiguration.getDefaultValue('dataPath'), studyTag);
         rawFile  = fullfile(filepath, self.rawDirectory,      [filename '.mat']);
         uiFile   = fullfile(filepath, self.readableDirectory, filename);
         
         %% Get the ecode matrix using the topsDataLog utility
         %
         % get the mainTreeNode
         mainTreeNodeStruct = topsDataLog.getTaggedData('mainTreeNode', rawFile);
         topNode = mainTreeNodeStruct.item;
         
         % Now read the ecodes -- note that this works only if the trial struct was
         % made only with SCALAR entries
         FIRA.ecodes = topsDataLog.parseEcodes('trial');
         
         %% Synchronize timing
         %
         % use name prefixes to sync times
         startInds = cell2num(strfind(FIRA.ecodes.name, 'trialStart'));
         for ii = find(startInds>0)
            Lmatch = cell2num(strfind(FIRA.ecodes.name, ...
               FIRA.ecodes.name{ii}(1:startInds(ii)-2)))>0;
            Lmatch(ii) = false;
            FIRA.ecodes.data(:,Lmatch) = FIRA.ecodes.data(:,Lmatch) - ...
               repmat(FIRA.ecodes.data(:,ii),1,sum(Lmatch));
         end
         
         % Calibrate all times to ref time
         timeInds = cell2num(strfind(FIRA.ecodes.name, 'time_'))>0;
         if any(timeInds)
            refInd   = strcmp(FIRA.ecodes.name, refTime);
            timeInds(refInd) = false;
            FIRA.ecodes.data(:,timeInds) = FIRA.ecodes.data(:,timeInds) - ...
               repmat(FIRA.ecodes.data(:,refInd), 1, sum(timeInds));
         end
         
         %% Get the analog data
         %
         % Use constructor class static method to read the data file.
         for ii = 1:length(topNode.sharedProperties.readableList)
            
            ui = topNode.sharedProperties.readableList{ii};
            
            % For now just for eye data... will need to generalize this later
            if isa(ui, 'dotsReadableEye')
               
               calibrationData = topsDataLog.getTaggedData('dotsReadableEye calibration');
               tli = find(strcmp(FIRA.ecodes.name, 'time_local_trialStart'), 1);
               tui = find(strcmp(FIRA.ecodes.name, 'time_ui_trialStart'), 1);
               twi = find(strcmp(FIRA.ecodes.name, refTime), 1);
               FIRA.analog = ui.readDataFromFile(ui, uiFile, FIRA.ecodes.data(:,[tli tui twi]), ...
                  calibrationData);
            end
         end
      end
   end
end