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
      trialData = struct( ...
         'taskID',       [], ...
         'trialIndex',   [], ...
         'trialStart',   [], ...
         'trialEnd',     []);
      
      % Index of current trial (in trialIndices array)
      trialCount = 0;
      
      % Number of times to run through this node's trials
      trialIterations = 1;
      
      % Index of blocks while running
      trialIteractionCount = 1;
      
      % How to run through this node's trials --'sequential' or
      % 'random' order
      trialIterationMethod = 'random';
      
      % Flag indicating whether or not to randomize order of repeated trial
      randomizeWhenRepeating = true;
      
      % Array of trial indices, in order of calling
      trialIndices = [];
      
      % Status strings to give feedback. We put them here in case a gui
      % needs them
      statusStrings = {};
   end
   
   properties (SetAccess = protected)
      
      % The state machine
      stateMachine
      
      % flag if successefully finished trial (or need to repeat)
      completedTrial = false;
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
         if self.caller.checkFlags(self) > 0
            return
         end
         
         % Do some bookkeeping via superclass
         self.start@topsRunnable();
         
         % Possibly update the gui using the new task
         self.caller.updateGUI('_updateTask', self);
         
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
            % self.helpers.(hh{:}).bind(self);
         end
         
         % Call sub-class startTask method
         self.startTask();
         
         % Set up trials
         %
         % If trialDataFields given, use to set up trialData struct
         if any(strcmp(properties(self), 'trialDataFields'))
            for ii = 1:length(self.trialDataFields)
               [self.trialData.(self.trialDataFields{ii})] = deal(nan);
            end
         end
         
         % Add trials from independent variables struct
         if any(strcmp(properties(self), 'independentVariables'))
            self.makeTrials(self.independentVariables);
         end         
         
         % Get the first trial
         self.prepareForNextTrial();
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
            % self.helpers.(hh{:}).bind(self);
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
      %  Utility to make trialData array using array of structs (independentVariables),
      %     which must be a property of the given task with fields:
      %
      %     1. name: string name
      %     2. values: vector of unique values
      %     3. priors: vector of priors (or empty for equal priors)
      %     4. minTrials: minimum number of trials per condition
      %
      function makeTrials(self, independentVariables)
         
         % Loop through to set full set of values for each variable
         for ii = 1:length(independentVariables)
            
            % Get min trials per condition
            mtr = 1;
            if isempty(independentVariables(ii).minTrials)
               if any(strcmp(properties(self), 'settings')) && ...
                     isfield(self.settings, 'minTrialsPerCondition')
                  mtr = self.settings.minTrialsPerCondition;
               end
            else
               mtr = independentVariables(ii).minTrials;
            end
            
            % Make array of values based on priors
            priors = independentVariables(ii).priors;
            values = independentVariables(ii).values;
            independentVariables(ii).values = [];
            if isempty(priors) || length(priors) ~= length(values)
               priors = repmat(mtr, size(values));
            end
            priors = round(priors./min(priors).*mtr);
            for jj = 1:length(priors)
               independentVariables(ii).values = cat(1, ...
                  independentVariables(ii).values, repmat( ...
                  values(jj), priors(jj), 1));
            end
            
            % Check that we got something
            if isempty(independentVariables(ii).values)
               return
            end
         end
         
         % get values as cell array and make ndgrid
         values = {independentVariables.values};
         grids  = cell(size(values));
         [grids{:}] = ndgrid(values{:});
         
         % update trialData struct array
         ntr = numel(grids{1});
         self.trialData = repmat(self.trialData(1), ntr, 1);
         [self.trialData.taskID] = deal(self.taskTypeID);
         trlist = num2cell(1:ntr);
         [self.trialData.trialIndex] = deal(trlist{:});
         for ii = 1:length(independentVariables)
            values = num2cell(grids{ii}(:));
            [self.trialData.(independentVariables(ii).name)] = deal(values{:});
         end
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
      function setTrialData(self, trialIndex, tag, value)
         
         if isempty(trialIndex)
            trialIndex = self.trialIndices(self.trialCount);
         else
            trialIndex = self.trialIndices(trialIndex);
         end
         
         % save with 'time_' prefix
         self.trialData(trialIndex).(tag) = value;
      end
      
      %% setIndependentVariableByName
      %
      % Utility... varargin is property/value pairs corresponding to the
      %  independentVariables struct array
      %
      function setIndependentVariableByName(self, name, varargin)
         
         Lind = strcmp({self.independentVariables.name}, name);
         for ii = 1:2:nargin-2
            self.independentVariables(Lind).(varargin{ii}) = varargin{ii+1};
         end
      end
      
      %% setIndependentVariablesByName
      %
      % independentVariableList is {'<nameA>' {<propertyA1>, <valueA1>, ...}
      %
      function setIndependentVariablesByName(self, independentVariableList)
         
         for ii = 1:2:length(independentVariableList)
            self.setIndependentVariableByName(independentVariableList{ii}, ...
               independentVariableList{ii+1}{:});
         end
      end
   end
   
   methods (Access = protected)
      
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
            self.helpers.(ff{:}).prepare(self);
            
            % Flush readables
            if ismethod(self.helpers.(ff{:}).theObject, 'flushData')
               self.helpers.(ff{:}).theObject.flushData();
            end
         end         
      end
      
      %% Finish a trial ... can be overloaded in task subclass
      %
      function finishTaskTrial(self)
         
         % ---- Call the subclass finishTrial method
         %
         self.finishTrial();
         
         % ---- Set finish time
         %
         self.setTrialData([], 'trialEnd', feval(self.clockFunction))         
         
         % ---- Save the current trial in the DataLog
         %
         %  We do this even if no choice was made, in case later we want
         %     to re-parse the UI data
         topsDataLog.logDataInGroup(self.getTrial(), ['trial_' self.name]);
         
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
         if self.caller.checkFlags(self) > 0
            return
         end
         
         % Check if we need to initalize the trialIndices array
         if ~isempty(self.trialData) && isempty(self.trialIndices)
            
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
         else
            
            % Check for repeat trial
            if ~self.completedTrial
               
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
               
               % Updating the trial!
               %
               % Increment the trial counter
               self.trialCount = self.trialCount + 1;
               
               % Check for end of trials
               if self.trialCount > length(self.trialIndices)
                  
                  % Increment iterations
                  self.trialIteractionCount = self.trialIteractionCount + 1;
                  
                  % Check for end of iterations
                  if self.trialIteractionCount > self.trialIterations
                     
                     % Done!
                     self.isRunning = false;
                  else
                     
                     % Recompute trialIndices array
                     self.trialIndices = [];
                     self.setNextTrial();
                  end
               end
            end
         end
      end
      
      %% show status
      %
      function updateStatus(self, indices)
         
         % Check arg
         if nargin < 2 || isempty(indices)
            indices = 1:length(self.statusStrings);
         end
         
         % Always print in command window
         % Loop through the indices
         for ii = indices
            if ii == 1
               disp(' ')
            end
            disp(self.statusStrings{ii})
         end
         
         % Possibly update the gui using the new task
         self.caller.updateGUI('_updateTaskStatus', self, indices);
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
   end
end
