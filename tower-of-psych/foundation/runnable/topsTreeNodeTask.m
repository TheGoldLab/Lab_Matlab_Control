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
   
   % 5/27/18 created by jig
   
   properties
      
      % Unique identifier
      taskID = -1;
      
      % Unique type identifier
      taskTypeID = -1;
      
      % An array of structs describing each trial
      trialData = struct( ...
         'taskID',      [], ...
         'trialIndex',  []);
      
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
      setRegistry = {'drawables', 'readables', 'playables'};
      
      % Whether or not to send TTLs
      sendTTLs = false;
      
      % Specify which timing fields to add to the trialData struct
      timingFields = struct( ...
         'name',           struct('prefix', 'local',  'tags', {{'trialStart'}}), ...
         'sendTTLs',       struct('prefix', 'local',  'tags', {{'TTLStart', 'TTLFinish'}}), ...
         'screenEnsemble', struct('prefix', 'screen', 'tags', {{'trialStart', 'roundTrip'}}), ...
         'readables',      struct('prefix', 'ui',     'tags', {{'trialStart', 'roundTrip'}}));
   end
   
   properties (SetAccess = protected)
      
      % The state machine
      stateMachine
      
      % flag if successefully finished trial (or need to repeat)
      completedTrial = false;
      
      % property update flags, set by setListeners
      updateFlags;
      
      % For sending TTLs
      TTLs = struct(       ...
         'channel',        0,       ... % Which channel
         'pauseTime',      0.2,     ... % Time (in sec) between pulses in a sequence
         'dOutObject',     []);         % The object

      % Properties that can be shared from the topsTreeNodeTopNode
      %
      sharedHelpers;
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
      
      %% Set up trialData
      %
      % values is cell array of string names
      % times is cell array of:
      %     <prefix>, {<names> ...}
      function setTrialData(self, values, times)
      
         % Values
         if nargin >= 2 && ~isempty(values)
            for ii = 1:length(values)
               self.trialData.(values{ii}) = nan;
            end
         end
         
         % Times
         if nargin >= 3 && ~isempty(times)
            for ii = 1:2:length(times)
               prefix = self.timingFields.(times{ii}).prefix;
               for jj = 1:length(times{ii+1})
                  self.trialData.(['time_' prefix '_' times{ii+1}{jj}]) = nan;
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
         
         % Look for properties from the topNode
         if ~isempty(self.caller)
            
            % Find the topNode
            topNode = self.caller;
            while ~isempty(topNode.caller)
               topNode = topNode.caller;
            end
            
            % Get shared helpers
            self.sharedHelpers = topNode.sharedHelpers;
         end
            
         % Check for TTLs -- if so, get the object
         if self.sendTTLs
            self.TTLs.dOutObject = feval( ...
               dotsTheMachineConfiguration.getDefaultValue('dOutClassName'));
         end
                 
         % initialize registered classes
         sself = struct(self);
         for fields = self.setRegistry
            if isfield(sself, fields{:})
               eval(sprintf('self.start_%s();', fields{:}))
            end
         end
         
         % Call sub-class startTask method
         self.startTask();
         
         % Add the timing fields to the trialData struct
         for ff = fieldnames(self.timingFields)'
            
            %% jig needs to fix
            % Only if the property exists
            if true % ~isempty(self.sharedHelpers.(ff{:}))
               
               % Special case of multiple objects -- use indexed prefix
               if false %iscell(self.(ff{:})) && length(self.(ff{:})) > 1
                  num = length(self.(ff{:}));
               else
                  num = 1;
               end
               prefix = self.timingFields.(ff{:}).prefix;
               for nn = 1:num
                  if num>1
                     prefix = sprintf('%s%d', prefix, nn);
                  end
                  for tt = self.timingFields.(ff{:}).tags
                     [self.trialData.(['time_' prefix '_' tt{:}])] = deal(nan);
                  end
               end
            end
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
         
         % Write data from the log to disk if the topNode defines a
         % filename
         if isa(self.caller, 'topsTreeNodeTopNode') && ...
               ~isempty(self.caller.dataFiles.filename)
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
      %                       See activateEnsemblesByState for details.
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
         % See activateEnsemblesByState for details.
         % Note that the predots state is what allows us to get a good timestamp
         %   of the dots onset... we start the flipping before, so the dots will start
         %   as soon as we send the isVisible command in the entry fevalable of showDots
         if nargin >= 3 && ~isempty(activeList)
            self.stateMachine.addSharedFevalableWithName( ...
               {@activateEnsemblesByState activeList}, 'activateEnsembles', 'entry');
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
         self.completedTrial = false;
         
         % ---- Get screen synchronization times
         if ~isempty(self.sharedHelpers.screenEnsemble)
            screenRoundTripTime = inf;
            start               = mglGetSecs();
            after               = start;
            while (screenRoundTripTime > 0.01) && ((after-start) < 0.5);
               before              = mglGetSecs();
               screenTime          = self.sharedHelpers.screenEnsemble.callObjectMethod(@getCurrentTime);
               after               = mglGetSecs();
               screenRoundTripTime = after - before;
            end
            localTime = mean([before after]);
         else
            localTime           = mglGetSecs();
            screenTime          = nan;
            screenRoundTripTime = nan;
         end
         
         % ---- Get ui times
         if ~isempty(self.sharedHelpers.readables)
            if iscell(self.sharedHelpers.readables)
               uiTimes          = nans(length(self.sharedHelpers.readables), 1);
               uiRoundTripTimes = nans(length(self.sharedHelpers.readables), 1);
               for ii = 1:length(self.sharedHelpers.readables)
                  before               = mglGetSecs();
                  deviceTime           = self.sharedHelpers.readables{ii}.getDeviceTime();
                  after                = mglGetSecs();       
                  uiTimes(ii)          = deviceTime - after + localTime;
                  uiRoundTripTimes(ii) = after - before;
               end
            else
               before           = mglGetSecs();
               deviceTime       = self.sharedHelpers.readables.getDeviceTime();
               after            = mglGetSecs();
               uiTimes          = deviceTime - after + localTime;
               uiRoundTripTimes = after - before;
            end
         else
            uiTimes          = nan;
            uiRoundTripTimes = nan;
         end
         
         % ---- Set them using standard syntax
         self.setTrialTime([], 'name',           1, localTime);
         self.setTrialTime([], 'screenEnsemble', 1, screenTime);
         self.setTrialTime([], 'screenEnsemble', 2, screenRoundTripTime);
         self.setTrialTime([], 'readables',      1, uiTimes);
         self.setTrialTime([], 'readables',      2, uiRoundTripTimes);
         
         % ---- Conditionally send TTL pulses (mod trial count)
         %
         if self.sendTTLs
            
            % Get time of first pulse
            [TTLStart, TTLRef] = self.TTLs.dOutObject.sendTTLPulse(self.TTLs.channel);

            % get the remaining pulses and save the finish time
            TTLFinish = TTLStart;
            for pp = 1:mod(self.trialCount,4)
               pause(self.TTLs.pauseTime);
               TTLFinish = self.TTLs.dOutObject.sendTTLPulse(self.TTLs.channel);
            end
            
            % Set them using timing tags
            start  = TTLRef - localTime;
            self.setTrialTime([], 'sendTTLs', 1, start);
            self.setTrialTime([], 'sendTTLs', 2, (TTLFinish - TTLStart) + start);
         end
         
         % ---- Call beginTrial method for the ui(s)
         for ii = 1:length(self.sharedHelpers.readables)
            self.sharedHelpers.readables{ii}.beginTrial();
         end
         
         % ---- call the subclass startTrial method
         self.startTrial();
      end
      
      %% Finish a trial ... can be overloaded in task subclass
      %
      function finishTaskTrial(self)
         
         % ---- Call the subclass finishTrial method
         %
         self.finishTrial();
         
         % ---- Call endTrial method for the ui(s)
         %
         for ii = 1:length(self.sharedHelpers.readables)
            self.sharedHelpers.readables{ii}.endTrial();
         end
         
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
      
      %% makeTrials
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
      
      %% The listeners
      %
      % Callback for PostSet event
      % Inputs: meta.property object, event.PropertyEvent
      function propertySetListener(self, source, event)
         
         % h = event.AffectedObject;
         self.updateFlags.(source.Name) = true;
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
      
      %% drawWithTimestamp(self, drawables, inds_on, inds_off, eventTag)
      %
      % Utility for setting isVisible flag of drawable objects to true/false,
      %  then sending a screen flip command and saving the timing in the
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
         ret = callObjectMethod(drawables, @dotsDrawable.drawFrame, {}, [], true);
            
         % Possibly store the timing data
         if nargin >= 5 && ~isempty(eventTag)
            self.setTrialTime([], 'screenEnsemble', eventTag, ret.onsetTime)
         end
      end
      
      %% setAndDrawWithTimestamp(self, drawables, args, eventTag)
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
            
            % Store the timing data
            self.setTrialTime([], 'screenEnsemble', eventTag, ret.onsetTime)
         end
      end
      
      %% showText
      %
      % Utility to show text using the textEnsemble or command window
      %
      % Optional arguments are:
      %  showDuration
      %  pauseDuration
      function showText(self, textStrings, eventTag, varargin)

         % check string format
         if ischar(textStrings)
            textStrings = {textStrings};
         end
         
         % jig : need to make more robust checks at some point
         if ~isempty(self.sharedHelpers.drawables)
%                length(self.sharedDrawableEnsemble.objects) >= size(textStrings,2) && ...
%                isa(self.sharedDrawableEnsemble.objects{1}, 'dotsDrawableText')
            
            % Draw using ensemble, getting timestamp
            ret  = dotsDrawableText.drawEnsemble(self.sharedHelpers.drawables, ...
               textStrings, true, varargin{:});
            drawTime = ret.onsetTime;
         else
            
            % Just show in the command window
            for ii = 1:length(textStrings)
               disp(textStrings{ii});
            end
            drawTime = mglGetSecs;
         end
         
         if nargin >= 3 && ~isempty(eventTag)
            self.setTrialTime([], 'screenEnsemble', eventTag, drawTime);
         end
      end

      %% getEventWithTimestamp
      %
      % Useful utility for saving the timing of the event in the trial data
      % struture.
      %
      % Arguments:
      %  theObject      ... dotsReadable object used to get the event
      %  acceptedEvents ... cell array of strings acceptedEvents to list
      %                       names of events that can be used.
      %  eventTag       ... string used to store timing information in trial
      %                       struct. Assumes that the current trialData
      %                       struct has an entry called time_<eventTag>.
      %
      function eventName = getEventWithTimestamp(self, theObject, ...
            acceptedEvents, eventTag)
         
         % Call dotsReadable.getNext
         %
         % data has the form [ID, value, time]
         [eventName, data] = theObject.getNextEvent([], acceptedEvents);
         
         if ~isempty(eventName)
            
            % Store the timing data
            self.setTrialTime([], 'readables', eventTag, data(3));
         end
      end
      
      %% Utility to save timing data in the trialData struct 
      %     using a standard format
      %
      function setTrialTime(self, trialIndex, timingType, tag, value, index)
         
         if isempty(trialIndex)
            trialIndex = self.trialCount;
         end
         
         if isnumeric(tag)
            tag = self.timingFields.(timingType).tags{tag};
         end
         
         if nargin < 6 || isempty(index)
            index = 1:length(value);
         end
         
         % First one is standard format
         self.trialData(self.trialIndices(trialIndex)).(sprintf('time_%s_%s', ...
            self.timingFields.(timingType).prefix, tag)) = value(index(1));

         if length(index)>1
            for ii = index(2:end)'
               self.trialData(self.trialIndices(trialIndex)).(sprintf('time_%s%d_%s', ...
                  self.timingFields.(timingType).prefix, ii, tag)) = value(ii);
            end
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
      
      %% setIndVarByName
      %
      % Utility... varargin is property/value pairs corresponding to the
      %  indVar struct array
      %
      function setIndVarByName(self, name, varargin)
         
         Lind = strcmp({self.indVars.name}, name);
         for ii = 1:2:nargin-2
            self.indVars(Lind).(varargin{ii}) = varargin{ii+1};
         end
      end
      
      %% setIndVarsByName
      %
      % indVarList is {'<nameA>' {<propertyA1>, <valueA1>, ...}
      %
      function setIndVarsByName(self, indVarList)
         
         for ii = 1:2:length(indVarList)
            self.setIndVarByName(indVarList{ii}, indVarList{ii+1}{:});
         end
      end
            
      %% Prepare readables for this trial
      %
      function prepareReadables(self)
         
         % ---- Reset the events for the given ui type from the property
         %        struct
         %
         if self.updateFlags.readables
            self.updateReadables();
         end
         
         % ---- Deactivate the events (they are activated in the statelist)
         %     and flush the UI
         %
         self.readables.theObject.deactivateEvents();
         self.readables.theObject.flushData();
      end
      
      %% Prepare drawables for this trial
      %
      % Overload in subclass if more functionality needed
      %
      function prepareDrawables(self)
         
         % ---- Conditionally update all stimulusEnsemble objects with
         %        default values
         %
         if self.updateFlags.drawables
            self.updateDrawables();
         end   
      end
      
      %% Prepare playables for this trial
      %
      % Overload in subclass if more functionality needed
      %
      function preparePlayables(self)
         
         % ---- Conditionally update all playables with values in property
         %        struct
         %
         if self.updateFlags.playables
            self.updatePlayables();
         end   
         
         % ---- Call prepareToPlay methods for each playable
         %
         if any(strcmp('playables', fieldnames(self)))
            for ff = fieldnames(self.playables)'
               if isa(self.playables.(ff{:}), 'dotsPlayable')
                  for pp = 1:length(self.playables.(ff{:}))
                     self.playables.(ff{:})(pp).prepareToPlay();
                  end
               end
            end
         end
      end
      
      %% updateReadables
      %
      % Utility for updating readables giving in properties in a standard
      % format. See modularTasks for examples
      function updateReadables(self)
         
         % parse the name
         classType = intersect(fieldnames(self.readables), ...
            cat(1, class(self.readables.theObject), ...
            superclasses(self.readables.theObject)));
         
         % use it to call defineEvents with the appropriate event definitions
         self.readables.theObject.defineEvents(self.readables.(classType{1}));
         
         % Unset flag
         self.updateFlags.readables = false;
      end
      
      %% updateDrawables
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
         
         % Unset the flag
         self.updateFlags.drawables = false;
      end
      
      %% updatePlayables
      %
      % Utility for updating readables giving in properties in a standard
      % format. See modularTasks for examples
      function updatePlayables(self)
         
         % Loop through the settings structs
         fields = fieldnames(self.playables);
         playableSettings = strfind(fields, 'Settings');
         for pp = find(~cellfun(@isempty,playableSettings))'
            object = self.playables.(fields{pp}(1:playableSettings{pp}-1));
            objectSettings = self.playables.(fields{pp});
            
            % For each object
            for ss = 1:length(objectSettings)
               
               % For each field
               for ff = fieldnames(objectSettings(ss))'
                  object(ss).(ff{:}) = objectSettings(ss).(ff{:});
               end
            end
         end
         
         % Unset flag
         self.updateFlags.playables = false;
      end
   end
   
   methods (Access = private)
             
      %% Initialize drawables at the beginning of the task using the property struct
      %
      % Create default drawables from the property list.
      %  Should be overloaded in subclass if doing anything else.
      function start_drawables(self)
         
         % ---- Check for screen
         %
         if isempty(self.sharedHelpers.screenEnsemble)
            error('topsTreeNodeTask: missing screenEnsemble');
         end
         
         % ---- Check for new drawable ensembles
         %
         fields = fieldnames(self.drawables);
         for dd = find(~cellfun(@isempty, regexp(fields, 'Ensemble$')))'
            
            if isempty(self.drawables.(fields{dd}))
               
               switch fields{dd}
                  
                  case 'textEnsemble'
                     
                     % Create the ensemble
                     self.drawables.textEnsemble = dotsDrawableText.makeEnsemble('textEnsemble', ...
                        2, self.settings.textOffset, self.sharedHelpers.screenEnsemble);
                     
                  otherwise % case 'stimulusEnsemble'
                     
                     sname = [fields{dd} 'Settings'];
                     if isfield(self.drawables, sname) && ~isempty(self.drawables.(sname))
                        objects = {self.drawables.(sname).type};
                        for oo = 1:length(objects)
                           objects{oo} = eval(objects{oo});
                        end
                        
                        % Make the ensemble
                        self.drawables.(fields{dd}) = dotsDrawable.makeEnsemble( ...
                           fields{dd}, objects, self.sharedHelpers.screenEnsemble, true);
                     end
               end
            end
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.drawables = true;
      end
      

      %% Initialize readables at the beginning of the task using the property struct
      %
      % Create default readable. Should be overloaded in subclass if doing
      % anything else.
      %
      function start_readables(self)
         
         % ---- Setup user input device
         %
         if isempty(self.readables.theObject) && ~isempty(self.sharedHelpers.readables)
            
            % default to first object given from parent
            self.readables.theObject = self.sharedHelpers.readables{1};
            
         elseif ~isempty(self.readables.theObject) && isempty(self.sharedHelpers.readables)
            
            % Register the object
            self.sharedHelpers.readables = {self.readables.theObject};
            
         else
            
            % Neither are present, do nothing
            return
         end
         
         % Check for dotsReadableEye
         if isa(self.readables.theObject, 'dotsReadableEye')
            
            % Bind stimulus ensemble to gaze windows
            [self.readables.dotsReadableEye.ensemble] = ...
               deal(self.drawables.stimulusEnsemble);
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.readables = true;
      end
      
      %% Initialize playables at the beginning of the task using the property struct
      %
      % Create default playables from the property list.
      %  Should be overloaded in subclass if doing anything else.
      %
      %  Example list:
      %       % Playable settings
      %       playables = struct( ...
      %          'dotsPlayableFile',              [], ...
      %          'dotsPlayableFileSettings',      struct( ...
      %          'fileName',                      {'', ''}, ...
      %          'isBlocking',                    {false, false}));
      %
      function start_playables(self)
         
         % ---- Create playables
         %
         fields = fieldnames(self.playables);
         for dd = find(~cellfun(@isempty, ...
               strfind(fields, 'dotsPlayable')) & ...
               cellfun(@isempty, strfind(fields, 'Settings')))'
            
            % Check for settings struct
            if isfield(self.playables, [fields{dd} 'Settings'])
               settings = self.playables.([fields{dd} 'Settings']);
               
               % make array of playables
               properties = fieldnames(settings);
               for ii = 1:length(settings)
                  playable = feval(fields{dd});
                  for pp = 1:length(properties)
                     playable.(properties{pp}) = settings(ii).(properties{pp});
                  end
                  self.playables.(fields{dd}) = cat(2, ...
                      self.playables.(fields{dd}), playable);
               end
               
            else
               self.playables.(fields{dd}) = feval(fields{dd});
            end
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.playables = true;
      end
   end
end
