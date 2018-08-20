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
            self.name, 'topsDataLog', ...
            sprintf('data_%.4d_%02d_%02d_%02d_%02d.mat', ...
            c(1), c(2), c(3), c(4), c(5)));
      end
   
      % Add the screen ensemble and possibly other common drawables
      %
      function addDrawables(self, displayIndex, remoteDrawing, addTextEnsemble)
         
         % ---- Check for drawables
         %
         if displayIndex >= 0
            
            % Make the screen ensemble
            self.sharedProperties.screenEnsemble = ...
               makeScreenEnsemble(remoteDrawing, displayIndex);
            
            % Add screen start/finish fevalables to the main topsTreeNode
            self.addCall('start', {@callObjectMethod, ...
               self.sharedProperties.screenEnsemble, @open}, 'openScreen');
            self.addCall('finish', {@callObjectMethod, ...
               self.sharedProperties.screenEnsemble, @close}, 'closeScreen');

            % Possibly make a text ensemble for showing messages
            %
            % NOTE that for now it only makes the ensemble with 2 objects
            if nargin > 3 && addTextEnsemble
               self.sharedProperties.textEnsemble = makeTextEnsemble('text', 2, ...
                  [], self.sharedProperties.screenEnsemble);
               self.addCall('finish', {@drawTextEnsemble, self.sharedProperties.textEnsemble, ...
                  {'All done.', 'Thank you!'}, 2, 0}, 'finalMessage');
            end
         end
      end
      
      % Add the common readables
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
               if isfield(ui, 'screenEnsemble')
                  ui.screenEnsemble = self.sharedProperties.screenEnsemble;
               end
               
               % Set up data recording
               if ~isempty(self.filename)
                  [path, name] = fileparts(self.filename);
                  ui.filepath = fullfile(path(1:find(path==filesep,1,'last')-1), 'dotsReadable');
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
      
      % Overloaded start function, to check for gui(s)
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
            
      % Overloaded finish function, needed because we might have started
      %  GUI but did not run anything
      function finish(self)
         
         if self.isStarted
            self.finish@topsRunnable();
         end
         
         % To be safe, always write data log to file
         if ~isempty(self.filename)            
            topsDataLog.writeDataFile();
         end
      end
      
      % Does GUI need updating?
      function updateGUI(self, name, varargin)
         
         if ~isempty(self.runGUIHandle)
            
            feval(self.runGUIname, [self.runGUIname name], ...
               self.runGUIHandle, [], guidata(self.runGUIHandle), varargin{:});
         end
      end
      
      % Check status flags. Return ~0 if something happened
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
      
      % add call to start/finish call list
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
end