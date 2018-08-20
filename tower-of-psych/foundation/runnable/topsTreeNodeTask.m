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
   % Assumes trialData is a struct and automatically adds timing fields
   %
   % Subclasses must re-define
   %  startTask
   %  finishTask
   
   % 5/27/18 created by jig
   
   properties
      
      % Unique identifier
      taskID = -1;
      
      % Unique type identifier
      taskTypeID = -1;
      
      % An array of structs describing each trial
      trialData = [];
      
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
      
      % Registry of set listeners... see topsTreeNodeTask
      setRegistry = {'drawables', 'readables'};
   end
   
   properties (SetAccess = protected)
      
      % The state machine, created locally
      stateMachine;
      
      % The state machine concurrent composite, created locally
      stateMachineComposite;
      
      % Cell array used as input to topsStateMachine.addMultipleStates
      % DEFINE IN STARTTASK
      stateMachineStates = {};
      
      % Cell array used as input to activateEnsemblesByState
      % DEFINE IN STARTTASK
      stateMachineActiveList = {};
      
      % Cell array of children to add to the stateMachineComposite
      % DEFINE IN STARTTASK
      stateMachineCompositeChildren = {};
      
      % List of other children to add
      otherChildren = {};
      
      % flag if successefully finished trial (or need to repeat)
      completedTrial = false;
      
      % property update flags, set by setListeners
      updateFlags;

      % Properties that can be shared from the topsTreeNodeTopNode
      %
      % Handle to screenEnsemble, for timing info
      screenEnsemble;
      
      % Handle to textEnsemble used for messages
      textEnsemble;
      
      % Cell array of readable objects
      readableList = {};
      
      % Cell array of playable objects
      playableList = {};
      
      % flag to use TTL pulses -- sets timing fields in trialData
      sendTTLs = false;
   end
   
   methods
      
      % Constuct with optional arguments.
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
         
         % ---- Keep track of changes to certain property structs
         %
         %  This will eventually be useful for real-time updating
         for ii = 1:length(self.setRegistry)
            if isfield(self, self.setRegistry{ii})
               self.updateFlags.(self.setRegistry{ii}) = false;
               % jig commented for now - not needed until/if realtime updating is
               %  added
               % Add the listeners
            %  addlistener(self, self.setRegistry{ii}, 'PostSet', @self.propertySetListener);
            end
         end
      end
      
      % Start task method
      %
      function start(self)
         
          % ---- Check status flags
         if self.caller.checkFlags(self) > 0
            return
         end
         
         % Do some bookkeeping via superclass
         self.start@topsRunnable();
         
         % Get some properties from the topNode
         if ~isempty(self.caller)
            
            % Find the topNode
            topNode = self.caller;
            while ~isempty(topNode.caller)
               topNode = topNode.caller;
            end
            
            for ff = fieldnames(topNode.sharedProperties)'
               if isempty(self.(ff{:}))
                  self.(ff{:}) = topNode.sharedProperties.(ff{:});
               end
            end
         end

         % Possibly update the gui using the new task
         self.caller.updateGUI('_updateTask', self);
         
         % Check for abort
         if ~self.isRunning
            return
         end
         
         % Call sub-class startTask method
         self.startTask();
         
         % Set up the state machine
         if ~isempty(self.stateMachineStates)
            self.stateMachine = topsStateMachine();
            self.stateMachine.addMultipleStates(self.stateMachineStates);
            self.stateMachine.startFevalable  = {@self.startTaskTrial};
            self.stateMachine.finishFevalable = {@self.finishTaskTrial};
            
            % Set up ensemble activation list.
            %
            % See activateEnsemblesByState for details.
            % Note that the predots state is what allows us to get a good timestamp
            %   of the dots onset... we start the flipping before, so the dots will start
            %   as soon as we send the isVisible command in the entry fevalable of showDots
            if ~isempty(self.stateMachineActiveList)
               self.stateMachine.addSharedFevalableWithName( ...
                  {@activateEnsemblesByState self.stateMachineActiveList}, ...
                  'activateEnsembles', 'entry');
            end
            
            % Make a concurrent composite to interleave run calls
            %
            self.stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
            
            % Add the state machine
            self.stateMachineComposite.addChild(self.stateMachine);
            
            % Add the other children from the given list
            for ii = 1:length(self.stateMachineCompositeChildren)
               self.stateMachineComposite.addChild(self.stateMachineCompositeChildren{ii});
            end
            
            % Add it as a child to the task
            %
            self.addChild(self.stateMachineComposite);
            
            % Add remaining children
            for ii = 1:length(self.otherChildren)
               self.addChild(self.otherChildren{ii});
            end
         end
         
         % Figure out which timing fields to add
         timingFields = {};
         
         % using TTLS
         if self.sendTTLs
            timingFields = cat(2, timingFields, ...
               {'TTLStart', 'TTLFinish'});
         end
         
         % screen object
         if ~isempty(self.screenEnsemble)
            timingFields = cat(2, timingFields, ...
               {'screen_trialStart', 'screen_roundTrip'});
         end
         
         % uis
         for ii = 1:length(self.readableList)
            if length(self.readableList) > 1
               uiStr = sprintf('ui%d', ii);
            else
               uiStr = 'ui';
            end
            timingFields = cat(2, timingFields, ...
               {[uiStr '_trialStart'], [uiStr '_roundTrip']});
         end
         
         % Now add the fields
         [self.trialData.time_local_trialStart] = deal(nan);
         for ii = 1:length(timingFields)
            [self.trialData.(['time_' timingFields{ii}])] = deal(nan);
         end
         
         % Get the first trial
         self.prepareForNextTrial();
      end
      
      % Finish task method
      %
      function finish(self)
         
         % Do some bookkeeping
         self.finish@topsRunnable();
         
         % Call sub-class finishTask method
         self.finishTask();
         
         % Write data from the log to disk if the topNode defines a
         % filename
         if ~isempty(self.caller.filename)
            topsDataLog.writeDataFile();
         end
      end
       
      % Blank startTask method -- overload in subclass
      %
      % Overloaded method can/should fill the following fields, as needed:
      %
      %  stateMachineStates
      %  stateMachineActiveList
      %  stateMachineCompositeChildren
      %
      function startTask(self)
      end
      
      % Blank finishTask method -- overload in subclass
      %
      function finishTask(self)
      end
   end
   
   methods (Access = protected)

      % Start a trial ... can be overloaded in task subclass
      %
      function startTaskTrial(self)
         
         % Reset completed flag
         self.completedTrial = false;
         
         % Get the current trial
         trial = self.getTrial();
         
         % Get synchronization times
         if length(self.readableList) <= 1
            [trial.time_local_trialStart, ...
               trial.time_screen_trialStart, ...
               trial.time_screen_roundTrip, ...
               trial.time_ui_trialStart, ...
               trial.time_ui_roundTrip] = ...
               syncTiming(self.screenEnsemble, ...
               self.readableList);            
         else
            % multiple ui objects, parse return arguments
            [trial.time_local_trialStart, ...
               trial.time_screen_trialStart, ...
               trial.time_screen_roundTrip, ...
               time_ui_trialStarts, ...
               time_ui_roundTrips] = ...
               syncTiming(self.screenEnsemble, ...
               self.readableList);
            
            for ii = 1:length(self.readableList)
               uiStr = sprintf('ui%d', ii);
               trial.(['time_' uiStr '_trialStart']) = time_ui_trialStarts(ii);
               trial.(['time_' uiStr '_roundTrip']) = time_ui_roundTrips(ii);
            end
         end
         
         % ---- Conditionally send TTL pulses (mod trial count)
         %
         if self.sendTTLs
            [trial.time_TTLStart, trial.time_TTLFinish] = ...
               sendTTLsequence(mod(self.trialCount,4)+1);
         end
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);
         
         % call the subclass startTrial method
         self.startTrial();
      end
      
      % Finish a trial ... can be overloaded in task subclass
      %
      function finishTaskTrial(self)
         
         % ---- Call the subclass finishTrial method
         %
         self.finishTrial();

         % ---- Save the current trial in the DataLog
         %
         %  We do this even if no choice was made, in case later we want
         %     to re-parse the UI data
         topsDataLog.logDataInGroup(self.getTrial(), 'trial');
         
         % ---- Prepare for the next trial
         %
         % We do this here instead of in startTrial because prepareForNextTrial
         % might terminate the task if no trials remain.
         self.prepareForNextTrial();         
      end
      
      % makeTrials
      %
      %  Utility to make trialData array using indVars array of structs, 
      %     which must be a property of the given task with fields:
      %  
      %     1. name: string name
      %     2. values: vector of unique values
      %     3. priors: vector of priors (or empty for equal priors)
      %     4. minTrials: minimum number of trials per condition
      %
      function makeTrials(self)
         
         % Loop through the arg list
         args = {};
         for ii = 1:length(self.indVars)
            args = cat(2, args, cell(3,1));
            args{1,end} = self.indVars(ii).name;
            uvals       = self.indVars(ii).values;
            priors      = self.indVars(ii).priors;
            mtr         = self.indVars(ii).minTrials;
            
            if isempty(mtr)
               mtr = self.settings.minTrialsPerCondition;
            end
            if isempty(priors)
               priors = ones(size(uvals));
            end
            
            % the "min" here ensures that the condition with the smallest
            % relative prior gets at least "trials per condition"
            priors = round(priors./min(priors).*mtr);
            for jj = 1:length(priors)
               args{2,end} = cat(1, args{2,end}, repmat(uvals(jj), priors(jj), 1));
            end
         end
         
         % ---- Fill in the trialData with relevant information
         %
         if ~isempty(args)
            
            % Make grids
            [args{3,:}] = ndgrid(args{2,:});
            
            % Reformat
            for ii = 1:size(args,2)
               args{3,ii} = args{3,ii}(:)';
            end
            ntr = length(args{3,1});
            
            % Check for trial struct, otherwise make a dummy
            if isempty(self.trialData)
               self.trialData.taskID = nan;
            end
            
            % make the trial struct array
            self.trialData = dealMat2Struct(self.trialData(1), ...
               'taskID',      repmat(self.taskTypeID,1,ntr), ...
               'trialIndex',  1:ntr, ...
               args{[1 3], :});
         else
            
            % no trials given
            self.trialData = [];
         end
      end
      
      % Get a trial struct by trialCount index
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
      
      % Set a trial struct by trialCount index
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
      
      % Finish the current trial and figure out what happens next.
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
      
      % The listener
      %
      % Callback for PostSet event
      % Inputs: meta.property object, event.PropertyEvent
      function propertySetListener(self, source, event)
         
         % h = event.AffectedObject;
         self.updateFlags.(source.Name) = true;
      end
            
      % show status
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
      
      % drawWithTimestamp(self, drawables, inds_on, inds_off, eventTag)
      %
      % Utility for setting isVisible flag of drawable objects to true/false,
      %  then possibly sending a screen flip command and saving the timing in the
      %  current trial structure
      %
      % Arguments:
      %  drawables    ... ensemble with objects to draw
      %  inds_on      ... indices of ensemble objects to set isVisible=true
      %  inds_off     ... indices of ensemble objects to set isVisible=false
      %  eventTag     ... string used to store timing information in trial
      %                    struct. Assumes that the current trialData
      %                    struct has an entry called time_<eventTag>.
      %
      % Created 5/10/18 by jig
      function drawWithTimestamp(self, drawables, inds_on, inds_off, eventTag)
         
         % Turn on
         if nargin >= 3 && ~isempty(inds_on)
            drawables.setObjectProperty('isVisible', true, inds_on);
         end
         
         % Turn off
         if nargin >= 4 && ~isempty(inds_off)
            drawables.setObjectProperty('isVisible', false, inds_off);
         end
         
         % Possibly draw now
         if nargin >= 5 && ~isempty(eventTag)
            
            % Draw the next frame. This returns a struct with args:
            %   - onsetTime: estimated onset time for this frame, which
            %        might be a time in the future
            %   - onsetFrame: number of frames elapsed between open() and
            %        this frame
            %   - swapTime: estimated time of the last video hardware
            %        refresh (e.g. "vertical blank"), which is alwasy a
            %        time in the past
            %   - isTight: whether this frame and the previous frame were
            %        adjacent (false if a frame was skipped)
            ret = callObjectMethod(drawables, @dotsDrawable.drawFrame, ...
               {}, [], true);
            
            % Store the timing data.
            self.trialData(self.trialIndices(...
               self.trialCount)).(sprintf('time_%s', eventTag)) = ret.onsetTime;
         end
      end
      
      % setAndDrawWithTimestamp(self, drawables, args, eventTag)
      %
      % Slightly more generel utility than setAndDrawWithTimestamp (see
      % above)
      %
      % Arguments:
      %  drawables    ... ensemble with objects to draw
      %  args         ... cell array of args to send to "setObjectProperty"
      %                    format: {<propertyName>, <value(s)>, <indices>}
      %                    also can be cell array of cell arrays.
      %  eventTag     ... string used to store timing information in trial
      %                    struct. Assumes that the current trialData
      %                    struct has an entry called time_<eventTag>.
      %
      % Created 6/22/18 by jig
      function setAndDrawWithTimestamp(self, drawables, args, eventTag)
         
         % Check for args to setObjectProperty
         if nargin >= 3 && ~isempty(args)
            if ~iscell(args{1})
               args = {args};
            end
            for ii = 1:length(args)
               drawables.setObjectProperty(args{ii}{:});
            end
         end
         
         % Possibly draw now
         if nargin >= 4 && ~isempty(eventTag)
            
            % Draw the next frame. This returns a struct with args:
            %   - onsetTime: estimated onset time for this frame, which
            %        might be a time in the future
            %   - onsetFrame: number of frames elapsed between open() and
            %        this frame
            %   - swapTime: estimated time of the last video hardware
            %        refresh (e.g. "vertical blank"), which is alwasy a
            %        time in the past
            %   - isTight: whether this frame and the previous frame were
            %        adjacent (false if a frame was skipped)
            ret = callObjectMethod(drawables, @dotsDrawable.drawFrame, ...
               {}, [], true);
            
            % Store the timing data.
            self.trialData(self.trialIndices(...
               self.trialCount)).(sprintf('time_%s', eventTag)) = ret.onsetTime;
         end
      end
      
      % getEventWithTimestamp
      %
      % Useful utility for saving the timing of the event in the trial data
      % struture.
      %
      % Arguments:
      %  userInput      ... dotsReadable object used to get the event
      %  acceptedEvents ... cell array of strings acceptedEvents to list
      %                       names of events that can be used.
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      %
      function eventName = getEventWithTimestamp(self, userInput, ...
            acceptedEvents, eventTag)
         
         % Call dotsReadable.getNext
         %
         % data has the form [ID, value, time]
         [eventName, data] = userInput.getNextEvent([], acceptedEvents);
         
         if ~isempty(eventName)
            
            % Store the timing data
            self.trialData(self.trialIndices(...
               self.trialCount)).(sprintf('time_%s', eventTag)) = data(3);
         end
      end
      
      % setNextState
      %
      % Utility to conditionally set the next state
      function setNextState(self, condition, thisState, nextStateIfTrue, nextStateIfFalse)
         
         if self.(condition)
            self.stateMachine.editStateByName(thisState, 'next', nextStateIfTrue);
         else
            self.stateMachine.editStateByName(thisState, 'next', nextStateIfFalse);
         end
      end
      
      % setIndVarByName
      %
      % Utility... varargin is property/value pairs corresponding to the 
      %  indVar struct array
      function setIndVarByName(self, name, varargin)
         
         Lind = strcmp({self.indVars.name}, name);
         for ii = 1:2:nargin-2
            self.indVars(Lind).(varargin{ii}) = varargin{ii+1};
         end
      end
      
      % setIndVarsByName
      %
      % indVarList is {'<nameA>' {<propertyA1>, <valueA1>, ...}      
      function setIndVarsByName(self, indVarList)
         
         for ii = 1:2:length(indVarList)
            self.setIndVarByName(indVarList{ii}, indVarList{ii+1}{:});
         end
      end
      
      % Initialize Readables
      %
      % Create default readable. Should be overloaded in subclass if doing
      % anything else.
      function initializeReadables(self)

         % ---- Setup user input device
         %
         if isempty(self.readables.userInput) && ~isempty(self.readableList)
            
            % default to first object given from parent
            self.readables.userInput = self.readableList{1};
            
         elseif ~isempty(self.readables.userInput) && isempty(self.readableList)
            
            % Register the object
            self.readableList = {self.readables.userInput};
         end
         
         % Check for dotsReadableEye
         if isa(self.readables.userInput, 'dotsReadableEye')

            % Bind stimulus ensemble to gaze windows
            [self.readables.dotsReadableEye.ensemble] = ...
               deal(self.drawables.stimulusEnsemble);
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.readables = true;
      end      
              
      %% Initialize Drawables
      %
      % Create default drawables from the property list. 
      %  Should be overloaded in subclass if doing anything else.
      function initializeDrawables(self)
      
         % ---- Check for screen
         %
         if isempty(self.screenEnsemble)
            error('topsTreeNodeTask: missing screenEnsemble');
         end
         
         % ---- Check for other drawables
         %
         fields = fieldnames(self.drawables);
         drawableSettings = strfind(fields, 'Settings');
         for dd = find(cellfun(@isempty,drawableSettings))'
            
            switch fields{dd}
               
               case 'stimulusEnsemble'
            
                  if isempty(self.drawables.stimulusEnsemble)
                     
                     objects = {self.drawables.stimulusEnsembleSettings.type};
                     for oo = 1:length(objects)
                        objects{oo} = eval(objects{oo});
                     end
                     
                     % Make the ensemble
                     self.drawables.stimulusEnsemble = makeDrawableEnsemble( ...
                        'stimulusEnsemble', objects, self.screenEnsemble, true);
                  end
                  
               case 'textEnsemble'
                  
                  if isempty(self.drawables.textEnsemble)
                     
                     % Create the ensemble
                     self.drawables.textEnsemble = makeTextEnsemble('textEnsemble', ...
                        2, self.settings.textOffset, self.screenEnsemble);                     
                  end
                  
               otherwise
                  
                  error('topsTreeNodeTask: unknown drawable type')
            end
         end

         % ---- Set flag to update first time through
         %
         self.updateFlags.drawables = true;
      end
      
      % Prepare readables for this trial
      %
      function prepareReadables(self)
         
         % ---- Reset the events for the given ui type
         %
         if self.updateFlags.readables
            
            % Utility for updating readables with standard property format
            self.updateReadables();
            
            % reset flag
            self.updateFlags.readables = false;
         end
         
         % ---- Deactivate the events (they are activated in the statelist)
         %     and flush the UI
         %
         self.readables.userInput.deactivateEvents();
         self.readables.userInput.flushData();
      end
      
      % updateReadables
      %
      % Utility for updating readables giving in properties in a standard
      % format. See modularTasks for examples
      function updateReadables(self)
         
         % parse the name
         classType = intersect(fieldnames(self.readables), ...
            cat(1, class(self.readables.userInput), ...
            superclasses(self.readables.userInput)));
         
         % use it to call defineEvents with the appropriate event definitions
         self.readables.userInput.defineEvents(self.readables.(classType{:}));         
      end
      
      % updateDrawables
      %
      % Utility for updating drawables giving in properties in a standard
      % format. See modularTasks for examples.
      function updateDrawables(self)
         
         % Loop through the ensembles
         fields = fieldnames(self.drawables);
         drawableSettings = strfind(fields, 'Settings');
         for dd = find(~cellfun(@isempty,drawableSettings))'
            ensemble = self.drawables.(fields{dd}(1:drawableSettings{dd}-1));
            ensembleSettings = self.drawables.(fields{dd});
            
            % For each ensemble object
            for ss = 1:length(ensembleSettings)
               settings = ensembleSettings(ss).settings;
               
               % For each field
               for ff = fieldnames(settings)'
                  ensemble.setObjectProperty(ff{:}, ...
                     settings.(ff{:}), ss);
               end
            end
         end
      end
   end
end
