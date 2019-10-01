classdef topsTreeNodeTask < topsTreeNode
   % @class topsTreeNodeTask
   %
   % A special-purpose version of a topsTreeNode with properties and
   % functions that facilitate operating with tasks. This is an alternative
   % approach than making the trials topsTreeNode children. Instead here
   % the trials are defined by an array of structs with trial-specific data
   % that can make it easy to dump that struct into the topsDataLog and
   % keep track of what is going on.
   %
   % Assumes trialData is a struct and automatically adds timing fields.
   % NOTE that this is not yet set up to handle multiple ui objects that
   % each have their own time-base gracefully.
   %
   % Subclasses must re-define
   %  startTask
   %  finishTask
   %
   % Can optionally define properties:
   %  independentVariables ... used by makeTrials()
   %
   %
   
   % 5/27/18 created by jig
   properties
      
      % Unique identifier
      taskID = -1;
      
      % Unique type identifier
      taskTypeID = -1;
      
      % An array of structs describing each trial
      trialData;
      
      % Index of current trial (in trialIndices array)
      trialCount = 0;
      
      % How to increment trials in prepareForNextTrial
      % 'auto'     ... automatically increment after each good trial
      % 'hazard'   ... probabilistically increment wrt fixed hazard
      incrementTrialMethod = 'auto';
      
      % For controlling incrementTrialMethod (should have a struct of args
      % for each method)
      incrementTrial = struct( ...
         'counter',      0, ...
         'hazard',       struct( ...
         'rate',         0, ...
         'minTrials',    0, ...
         'maxTrials',    inf));
      
      % Number of times to run through this node's trials
      trialIterations = 1;
      
      % How to run through this node's trials --'sequential' or
      % 'random' order
      trialIterationMethod = 'random';
      
      % Flag indicating whether or not to randomize order of repeated trial
      randomizeWhenRepeating = true;
      
      % Inter-trial interval, in seconds
      interTrialInterval = 1.0;
      
      % Array of trial indices, in order of calling
      trialIndices = [];
      
      % Time to pause before task starts. Negative means wait for 't'
      % keypress if control helper is set up
      pauseBeforeTask = 0;
   end
   
   properties (SetAccess = protected)
      
      % The state machine
      stateMachine
      
      % flag if successefully finished trial (or need to repeat)
      completedTrial = false;
      
      % Control keyboard active flags, so we can reset them
      controlActiveFlags;
      
      % Default trialData fields
      trialDataDefaultFields = {'taskID', 'trialIndex', 'trialStart', 'trialEnd'};
   end
   
   methods
      
      %% Constuct with optional arguments.
      %
      % If any arguments are given, the first one must be the name.
      % Any remaining arguments are property/value pairs -- and note that
      % properties can be cell array of strings for property structs
      function self = topsTreeNodeTask(varargin)
         
         if nargin == 0
            name = 'topsTreeNodeTask';
         else
            name = varargin{1};
         end
         self = self@topsTreeNode(name);
         
         % Default is to iterate children until instructed to stop
         self.iterations = inf;
         
         if nargin > 1
            for ii = 2:2:nargin
               
               if ischar(varargin{ii})
                  
                  % property name given
                  self.(varargin{ii}) = varargin{ii+1};
                  
               elseif iscell(varargin{ii})
                  
                  % parse struct fields from cell array
                  str = 'self';
                  for jj = 1:length(varargin{ii})
                     if ischar(varargin{ii}{jj})
                        str = cat(2, str, ['.' varargin{ii}{jj}]);
                     elseif isscalar(varargin{ii}{jj})
                        str = cat(2, str, sprintf('(%d)', varargin{ii}{jj}));
                     end
                  end
                  eval([str ' = varargin{ii+1};']);
               end
            end
         end
      end
      
      %% Start task method
      %
      function start(self)
         
         % ---- Check status flags
         if ~isempty(self.caller) && self.caller.checkFlags(self) > 0
            return
         end
         
         % Do some bookkeeping via superclass
         self.start@topsRunnable();
         
         % Check for abort
         if ~self.isRunning
            return
         end
         
         % Set up Helpers
         %
         % Add default helpers
         self.addHelpers();
         
         % Call each helper's start method
         for hh = fieldnames(self.helpers)'
            self.helpers.(hh{:}).start(self);
         end
         
         % By default, set the taskID to the taskTypeID if it isn't
         % already set to something else
         if self.taskID == -1 && self.taskTypeID ~= -1
            self.taskID = self.taskTypeID;
         end
         
         % Call child's startTask method
         self.startTask();
         
         % Make trials -- note that this can always be done in the task
         %  if this field is blank
         if any(strcmp(properties(self), 'independentVariables'))
            
            if ischar(self.independentVariables)

               % If string is given, treat it as a filename and call load
               self.loadTrials(self.independentVariables)
            else
               
               % Otherwise add trials from independent variables struct.            
               self.makeTrials();
            end
            
         else
            
            % Just make empty set
            self.makeTrialData();
         end
         
         % Get the first trial
         self.prepareForNextTrial();
         
         % Possibly update the gui using the new task
         if ~isempty(self.caller)
            self.caller.updateGUI('_updateTask', self);
         end
         
         % Possibly pause
         if self.pauseBeforeTask~=0
            
            % Check if the control helper is set up ... if so, use it
            kb = self.activateControlKeyboard(true);
            if ~isempty(kb)
               
               % Make a message showing all of the commands
               message = {{'Using the control keyboard:', 'fontSize', 40}};
               for ff = fieldnames(self.caller.controlFlags)'
                  message = cat(2, message, {{['For ' ff{:} ' press ' ...
                     lower(self.caller.controlFlags.(ff{:}).key(end))], ...
                     'fontSize', 30}});
               end
               
               % Show message, possibly with check 
               if self.pauseBeforeTask < 0
                  
                  % Add continue message
                  message = cat(2, message, {{'PRESS T TO START TASK', 'fontSize', 30}});
                  topsTaskHelperMessage.showTextMessage(message, 'duration', 0);
                  
                  % Wait for keypress
                  ret = kb.waitForEvents({'taskStart', 'quit'}, inf);
                  
                  % Check for quit
                  if strcmp(ret, 'quit')
                     self.caller.abort();
                  end
               
               else
                  
                  % Just pause
                  topsTaskHelperMessage.showTextMessage(message);
                  pause(self.pauseBeforeTask);
               end
               
               % Blank the screen if necessary
               if dotsTheScreen.isOpen
                  dotsTheScreen.blankScreen();
               end
               
            elseif self.pauseBeforeTask > 0
               
               % Just pause
               pause(self.pauseBeforeTask);
            end
         end
      end
      
      %% Finish task method
      %
      function finish(self)
         
         % Do some bookkeeping
         self.finish@topsRunnable();
         
         % Call sub-class finishTask method
         self.finishTask();
         
         % Call each helper's finish method
         for hh = fieldnames(self.helpers)'
            self.helpers.(hh{:}).finish(self);
         end
         
         % Write data from the log to disk if the topNode defines a
         % filename
         if isa(self.caller, 'topsTreeNodeTopNode') && ...
               ~isempty(self.caller.filename)
            topsDataLog.writeDataFile();
         end
      end
      
      %% Blank startTask method -- overload in subclass
      %
      % Overloaded method can/should fill the following fields, as needed:
      %
      %  stateMachineStates
      %  stateMachineActiveList
      %  stateMachineCompositeChildren
      %
      function startTask(self)
      end
      
      %% Blank finishTask method -- overload in subclass
      %
      function finishTask(self)
      end
      
      %% makeTrials
      %
      %  Utility to make trialData array using array of structs, which
      %     is by convention stored as task.independentVariables. This
      %     struct is assumed to be organized as:
      %        struct.(propertyName).values
      %        struct.(propertyName).priors
      %
      %  trialIterations is number of repeats of each combination of
      %     independent variables
      %
      function makeTrials(self, independentVariables, trialIterations)
         
         % Check args
         if nargin < 2 || isempty(independentVariables)
            independentVariables = self.independentVariables;
         end
         if nargin < 3 || isempty(trialIterations)
            trialIterations = self.trialIterations;
         end
         
         % Loop through to set full set of values for each variable, and
         % collect them
         names = fieldnames(independentVariables);
         numVariables = length(names);
         allValues = cell(1, length(names));
         for ii = 1:numVariables
            
            % CHECK FOR FORMAT
            %
            if ~isstruct(independentVariables.(names{ii}))
               independentVariables.(names{ii}) = struct('values', ...
                  independentVariables.(names{ii}));
            end
            
            % CHECK FOR PRIORS
            %
            % Update values based on priors, if they are given in the
            % format: [proportion_value_1 proportion_value_2 ... etc]
            if isfield(independentVariables.(names{ii}), 'priors') && ...
                  length(independentVariables.(names{ii}).priors) == ...
                  length(independentVariables.(names{ii}).values) && ...
                  sum(independentVariables.(names{ii}).priors) > 0
               
               % rescale priors by greatest common divisor
               priors = independentVariables.(names{ii}).priors;
               priors = priors./gcd(sym(priors));
               
               % now re-make values array based on priors
               values = [];
               for jj = 1:length(priors)
                  values = cat(1, values, repmat( ...
                     independentVariables.(names{ii}).values(jj), priors(jj), 1));
               end
               
               % re-save the values
               independentVariables.(names{ii}).values = values;
            end
            
            % Save value(s), replacing [] with nan
            allValues{ii} = independentVariables.(names{ii}).values;
            if isempty(allValues{ii})
               allValues{ii} = nan;
            end
         end
         
         % get values as cell array and make ndgrid
         grids  = cell(size(allValues));
         [grids{:}] = ndgrid(allValues{:});
         
         % make an array of structures, the loop through the independent 
         %  variables and fill in values. Note that we repeat each set 
         %  trialIterations times.
         
         ivStruct = repmat(cell2struct(cell(size(names)), names, 1), ...
            numel(grids{1}) * trialIterations, 1);
         for ii = 1:numVariables
            values = num2cell(repmat(grids{ii}(:), trialIterations, 1));
            [ivStruct.(names{ii})] = deal(values{:});
         end
         
         % Make the struct
         self.makeTrialData(ivStruct);
      end
      
      % Utility for taking an array of structs, adding default fields and 
      %  storing as self.trialData
      %
      % ivStruct is the structure of independent variable values
      %
      function makeTrialData(self, ivvStruct)
         
         % Always add the defaults
         self.trialData = cell2struct(cell(size(self.trialDataDefaultFields)), ...
            self.trialDataDefaultFields, 2);
         
         % Add the given trialDataFields
         if any(strcmp(properties(self), 'trialDataFields'))
            for ii = 1:length(self.trialDataFields)
               [self.trialData.(self.trialDataFields{ii})] = deal(nan);
            end
         end
                  
         % Add independent variables, if given
         if nargin >= 2 && ~isempty(ivvStruct)
            
            % Compute total number of trials using the given struct
            ntr = length(ivvStruct);
            
            % Add the trials to the existing fields
            self.trialData = repmat(self.trialData, ntr, 1);
            
            % Add task ID, trials
            [self.trialData.taskID] = deal(self.taskID);
            trlist = num2cell(1:ntr);
            [self.trialData.trialIndex] = deal(trlist{:});
            
            % Now add the data from the given struct
            for ff = fieldnames(ivvStruct)'
               [self.trialData.(ff{:})] = deal(ivvStruct.(ff{:}));
            end         
         end
      end
      
      %% loadTrials
      %
      %  Utility to load trialData from a file.
      %
      function loadTrials(self, filename)
         
         % Get filename
         if nargin < 2 || isempty(filename)
            filename = 'trials.csv';
         end
         
         % Load the table
         theTable = readtable(filename);
         
         % Convert it to a struct
         ivvStruct = table2struct(theTable);
         
         % Make trialData array
         self.makeTrialData(ivvStruct);    
         
         % Save it in the correct format in independentVariables
         self.independentVariables = struct();         
         for ff = fieldnames(ivvStruct)'
            self.independentVariables.(ff{:}) = [ivvStruct.(ff{:})];
         end         
      end
      
      %% saveTrials
      %
      %  Utility to save trialData to a file.
      %
      %  Arguments:
      %   filename      ... string name, possibly with path
      %   variableList  ... cell array of string names of variables to save
      %
      function saveTrials(self, filename, variableList)
         
         % Get filename
         if nargin < 2 || isempty(filename)
            filename = 'trials.csv';
         end
         
         % Get the list of independent variables to save
         if nargin < 3 || isempty(variableList)

            variableList = {};

            if any(strcmp(properties(self), 'independentVariables')) && ...
                  ~isempty(self.independentVariables)
               
               % Try to get from independent variables struct
               variableList = fieldnames(self.independentVariables);
               
            elseif ~isempty(self.trialData)
               
               % Try to get from trialData struct(s)
               variableList = setdiff(fieldnames(self.trialData(1)), ...
                  self.trialDataDefaultFields);
            end
            
            if isempty(variableList)
               return
            end
            
         elseif strcmp(variableList, 'all')
            
            % Save everything
            variableList = fieldnames(self.trialData(1));
         end
         
         % Make the reduced struct
         structsToSave = rmfield(self.trialData, ...
            setdiff(fieldnames(self.trialData(1)), variableList));
         
         % Make the table
         theTable = struct2table(structsToSave);
         
         % Save it
         writetable(theTable, filename);
      end
      
      %% Get a trial struct by trialCount index
      %
      function trial = getTrial(self, trialCount)
         
         % Default is the current trial
         if nargin < 2 || isempty(self.trialCount)
            trialCount = self.trialCount;
         end
         
         % Use the index from self.trialIndices to get the trial
         if trialCount > 0 && trialCount <= length(self.trialIndices)
            trial = self.trialData(self.trialIndices(trialCount));
         else
            trial = [];
         end
      end
      
      %% Set a trial struct by trialCount index
      %
      function setTrial(self, trial, trialCount)
         
         % Default is the current trial
         if nargin < 3 || isempty(self.trialCount)
            trialCount = self.trialCount;
         end
         
         % Use the index from self.trialIndices to set the trial
         if trialCount > 0 && trialCount <= length(self.trialIndices)
            self.trialData(self.trialIndices(trialCount)) = trial;
         end
      end
      
      %% Utility to save timing data in the trialData struct
      %     using a standard format
      %
      function setTrialData(self, trialIndex, varargin)
         
         if isempty(trialIndex)
            trialIndex = self.trialIndices(self.trialCount);
         else
            trialIndex = self.trialIndices(trialIndex);
         end
         
         % Varargin is property/value pairs
         for ii = 1:2:nargin-2
            self.trialData(trialIndex).(varargin{ii}) = varargin{ii+1};
         end
      end   
      
      %% Utility for getting trialData value(s)
      %
      function data = getTrialData(self, fieldName, trialIndex)
         
         % Check whether we are getting a single value or all unique        
         if nargin < 3 || isempty(trialIndex)
            
            % All unique values
            data = unique([self.trialData.(fieldName)]);
         else
            
            % Single value
            data = self.trialData(trialIndex).(fieldName);
         end       
      end
      
      %% Utility function to set the value of a property 
      %  in the current trial data struct
      %
      function setTrialDataValue(self, name, value, trialIndex)
         
         if nargin < 4 || isempty(trialIndex)
            trialIndex = self.trialIndices(self.trialCount);
         else
            trialIndex = self.trialIndices(trialIndex);
         end
         
         % Set the value
         self.trialData(trialIndex).(name) = value;
      end
      
      %% Utility function to blank the screen and save a timestamp
      %
      % name is string name of trialData field
      function blankScreen(self, name)
         
         % Blank the screen
         frameInfo = dotsTheScreen.blankScreen();
         
         % Possibly save the timestamp
         if nargin >= 2 && ~isempty(name)
            self.trialData(self.trialIndices(self.trialCount)).(name) = ...
               frameInfo.onsetTime;
         end
      end   
   end
   
   methods (Access = protected)
      
      %% Utility to add a state machine that sets up drawing
      %
      % Varargin is in pairs:
      %  1. name of ensemble to be found in self.helpers.(name).theObject
      %  2. list of state names in which the ensemble should be
      %        drawn and the screen flipped automatically (e.g., for dots)
      function addStateMachineWithDrawing(self, states, varargin)
         
         numEnsembles = length(varargin)/2;
         activeList = cell(numEnsembles, 2);
         compositeChildren = cell(numEnsembles+1, 1);
         for ii = 1:numEnsembles
            ensemble = self.helpers.(varargin{(ii-1)*2+1}).theObject;
            activeList{ii,1} = {ensemble, 'draw'; ...
               self.helpers.screenEnsemble.theObject, 'flip'};
            activeList{ii,2} = varargin{(ii-1)*2+2};
            compositeChildren{ii} = ensemble;
         end
         
         % add the screen
         compositeChildren{end} = self.helpers.screenEnsemble.theObject;
         
         % call addStateMachine to do the work
         self.addStateMachine(states, activeList, compositeChildren);
      end
      
      %% Utility to add a state machine
      %
      % Arguments:
      %  states      ... the cell array of state specs for
      %                       topsStateMachine.addMultipleStates
      %  activeList  ... This determines which states will correspond to
      %                       automatic, repeated calls to the given
      %                       ensemble methods.
      %                       See topsActivateEnsemblesByState for details.
      %  compositeChildren ... Cell array of children to add to the
      %                       stateMachineComposite
      %  nodeChildren ... Cell array of children to add to this topsTreeNode
      function addStateMachine(self, states, activeList, compositeChildren, nodeChildren)
         
         % Set up the state machine
         self.stateMachine = topsStateMachine();
         self.stateMachine.addMultipleStates(states);
         self.stateMachine.startFevalable  = {@self.startTaskTrial};
         self.stateMachine.finishFevalable = {@self.finishTaskTrial};
         
         % Set up ensemble activation list.
         %
         % See topsActivateEnsemblesByState for details.
         % Note that the predots state is what allows us to get a good timestamp
         %   of the dots onset... we start the flipping before, so the dots will start
         %   as soon as we send the isVisible command in the entry fevalable of showDots
         if nargin >= 3 && ~isempty(activeList)
            self.stateMachine.addSharedFevalableWithName( ...
               {@topsActivateEnsemblesByState activeList}, 'activateEnsembles', 'entry');
         end
         
         % Make a concurrent composite to interleave run calls
         %
         stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
         
         % Add the state machine
         stateMachineComposite.addChild(self.stateMachine);
         
         % Add the other children from the given list
         if nargin >= 3 && ~isempty(compositeChildren)
            for ii = 1:length(compositeChildren)
               stateMachineComposite.addChild(compositeChildren{ii});
            end
         end
         
         % Add it as a child to the task
         %
         self.addChild(stateMachineComposite);
         
         % Add remaining children to this task node
         if nargin >= 5 && ~isempty(nodeChildren)
            for ii = 1:length(nodeChildren)
               self.addChild(nodeChildren{ii});
            end
         end
      end
      
      %% Start a trial ... can be overloaded in task subclass
      %
      function startTaskTrial(self)
         
         % ---- Reset completed flag
         %
         self.completedTrial = false;
         
         % ---- Save start time
         %
         startTime = feval(self.clockFunction);
         self.setTrialData([], 'trialStart', startTime)
         
         % ---- call the subclass startTrial method
         %
         self.startTrial();
         
         % ---- Prepare the helpers, including reference (trial start) time
         %
         for ff = fieldnames(self.helpers)'
            self.helpers.(ff{:}).sync.results.referenceTime = startTime;
            self.helpers.(ff{:}).startTrial(self);
            
            % Flush readables
            if ismethod(self.helpers.(ff{:}).theObject, 'flushData')
               self.helpers.(ff{:}).theObject.flushData();
            end
         end
      end
      
      %% Finish a trial ... can be overloaded in task subclass
      %
      function finishTaskTrial(self)
         
         % ---- Finsh helpers
         %
         for ff = fieldnames(self.helpers)'
            self.helpers.(ff{:}).finishTrial(self);
         end
         
         % ---- Call the subclass finishTrial method
         %
         self.finishTrial();
         
         % ---- Set finish time
         %
         currentTime = feval(self.clockFunction);
         self.setTrialData([], 'trialEnd', currentTime);
         
         % ---- Save the current trial in the DataLog
         %
         %  We do this even if no choice was made, in case later we want
         %     to re-parse the UI data
         topsDataLog.logDataInGroup(self.getTrial(), ['trial_' self.name]);
         
         % ---- Wait during the ITI and possibly check control keyboard
         %
         % Only bother if interTrialInterval is >0
         if self.interTrialInterval > 0
            
            % Get the control keyboard
            kb = self.activateControlKeyboard();
            
            % Check keyboard while waiting
            originalCurrentTime = currentTime;
            while feval(self.clockFunction) < currentTime + self.interTrialInterval
               
               if ~isempty(kb)
                  
                  % Check for keyboard event
                  event = kb.getNextEvent();
                  
                  % Got something, restricted to active events (from controlFlags)
                  if ~isempty(event)
                     
                     % Check event
                     if strcmp(event, 'pause')
                        
                        % Pause
                        if isfinite(currentTime) 
                           currentTime = inf;
                        else
                           currentTime = originalCurrentTime;
                        end
                        
                     elseif strcmp(event, 'calibrate')
                        
                        % Calibrate the active reader
                        if isfield(self.helpers, 'reader')
                           self.caller.controlFlags.calibrate.flag = self.helpers.reader.theObject;
                           break;
                        end
                        
                     else
                        
                        % Set flag
                        self.caller.controlFlags.(event).flag = true;
                        break;
                     end
                  end
               end
               
               % Wait and process GUI
               % drawnow; % needed?
               pause(0.002);
            end
            
            % Reset the active flags
            if ~isempty(kb)
               self.deactivateControlKeyboard();
            end
         end
         
         % ---- Prepare for the next trial
         %
         % We do this here instead of in startTrial because prepareForNextTrial
         % might terminate the task if no trials remain.
         self.prepareForNextTrial();
      end
      
      %% Finish the current trial and figure out what happens next.
      %     If done with this task, call the task's finish() routine,
      %     which should allow the parent topsTreeNode to find the next task.
      %
      % Checks self.completedTrial, a boolean flag indicating that this trial
      % finished or needs to be repeated
      function prepareForNextTrial(self)
         
         % ---- Check status flags
         if ~isempty(self.caller) && self.caller.checkFlags(self) > 0
            return
         end
         
         if ~isempty(self.trialData) && isempty(self.trialIndices)
            
            % Check if we need to initalize the trialIndices array
            %
            % Make array of indices
            if strcmp(self.trialIterationMethod, 'random')
               
               % Randomized
               self.trialIndices = randperm(numel(self.trialData));
            else
               
               % Sequential
               self.trialIndices = 1:numel(self.trialData);
            end
            
            % Start the counter
            self.trialCount = 1;
            
         elseif ~self.completedTrial
            
            % Check for repeat trial
            %
            % If randomizing, reorder the remaining trialIndices array.
            %     Otherwise do nothing
            if self.randomizeWhenRepeating && ...
                  strcmp(self.trialIterationMethod, 'random')
               
               % Get the number of remaining trials (+1 because including
               % the current trial)
               numRemainingTrials = length(self.trialIndices) - self.trialCount + 1;
               
               % permute the remaining indices
               inds = self.trialIndices(end-numRemainingTrials+1:end);
               self.trialIndices(end-numRemainingTrials+1:end) = ...
                  inds(randperm(numRemainingTrials));
            end
            
            % unset flag
            self.completedTrial = false;
            
         else
            
            % Check increment trial method
            switch self.incrementTrialMethod
               
               case 'auto'
                  
                  % Default: always increment after a good trial
                  self.trialCount = self.trialCount + 1;
                  
               case 'hazard'
                  
                  % Hazard: update according to a hazard rate and
                  % min/max trial numbers since previous change
                  
                  % Increment the trial counter
                  self.incrementTrial.counter = ...
                     self.incrementTrial.counter + 1;
                  
                  % Check for switch
                  %  > min value AND any one of these:
                  % 1. no max
                  % 2. > max
                  % 3. hit the hazard probability
                  if self.incrementTrial.counter >= ...
                        self.incrementTrial.hazard.minTrials && ...
                        (isempty(self.incrementTrial.hazard.maxTrials) || ...
                        self.incrementTrial.counter >= ...
                        self.incrementTrial.hazard.maxTrials || ...
                        rand() <= self.incrementTrial.hazard.rate)
                     
                     % Update trial count
                     self.trialCount = self.trialCount + 1;
                     
                     % Reset the counter
                     self.incrementTrial.counter = 0;
                     
                  else
                     
                     % just return
                     return
                  end
            end
            
            % Check for end of trials
            if self.trialCount > length(self.trialIndices)
               
               % Done!
               self.isRunning = false;
            end
         end
      end
      
      %% show status
      %
      function updateStatus(self, taskStatusString, trialStatusString)
         
         % Check for taskStatusString
         if nargin < 2
            taskStatusString = '';
         elseif ~isempty(taskStatusString)
            disp(' ')
            disp(taskStatusString)
         end
         
         % Check for trialStatusString
         if nargin < 3
            trialStatusString = '';
         elseif ~isempty(trialStatusString)
            disp(trialStatusString)
         end
         
         % Update GUI
         if ~isempty(self.caller)
            self.caller.updateGUI('_updateStatusStrings', self, taskStatusString, trialStatusString);
         end
      end
      
      %% setNextState
      %
      % Utility to conditionally set the next state
      %
      function setNextState(self, condition, thisState, nextStateIfTrue, nextStateIfFalse)
         
         if self.(condition)
            self.stateMachine.editStateByName(thisState, 'next', nextStateIfTrue);
         else
            self.stateMachine.editStateByName(thisState, 'next', nextStateIfFalse);
         end
      end
      
      %% debugStates
      %
      % Utility to set a flag in the state machine that will print out 
      %  each state name as it is entered
      % 
      function debugStates(self, debugFlag)
         
         if nargin < 2 || isempty(debugFlag)
            debugFlag = true;
         end
         
         self.stateMachine.debugFlag = debugFlag;
      end      
         
      %% activateControlKeyboard
      % 
      % Utility to set up the control keyboard to check for inputs 
      %
      % Get all activeFlag values in case the keyboard is being used for
      % something else and the statelist expects certain events to
      % be active... then just set the ones in the control flags struct
      function kb = activateControlKeyboard(self, activateAll)
         
         if isfield(self.helpers, 'controlKeyboard')
            kb = self.helpers.controlKeyboard.theObject;
            kb.flushData();
            kb.activateEventSet('control');
            
            if nargin >= 2 && activateAll
               kb.activateEvents();
            end
         else
            kb = [];
         end
      end
         
      %% deactivateControlKeyboard
      % 
      % Utility to set up the control keyboard to check for inputs 
      %
      function deactivateControlKeyboard(self)
         
         if isfield(self.helpers, 'controlKeyboard')
            kb = self.helpers.controlKeyboard.theObject;
            kb.flushData();
            kb.activateEventSet('default');
         end
      end         
   end
end
