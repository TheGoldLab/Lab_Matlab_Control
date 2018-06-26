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
   % 5/27/18 created by jig
   
   properties
      
      % Unique identifier
      taskID = [];
      
      % Unique type identifier
      taskTypeID = [];
      
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
   end   
   
   properties (SetAccess = protected)
      
      % flag to repeat trial
      repeatTrial = false;      
   end
   
   methods
      
      % Constuct with optional arguments.
      %
      % If any arguments are given, the first one must be the name.
      % Any remaining arguments are property/value pairs -- and note that
      % properties can be cell array of strings for property structs
      function self = topsTreeNodeTask(varargin)
         self = self@topsTreeNode(varargin{1});
         
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
      
      % Start task method
      function start(self)
         
         % ---- Check status flags
         if self.caller.checkFlags(self) > 0
            return
         end
         
         % Do some bookkeeping via superclass
         self.start@topsRunnable();

         % Possibly update the gui using the new task
         self.caller.updateGUI('_updateTask', self);         
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
      % Argument repeatTrial is a boolean flag indicating that this trial
      % needs to be repeated
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
            if self.repeatTrial
               
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
               self.repeatTrial = false;
               
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
   end
   
   methods (Access = protected)
      
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
         [eventName, data] = getNextEvent(userInput, [], acceptedEvents);

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
   end   
end
