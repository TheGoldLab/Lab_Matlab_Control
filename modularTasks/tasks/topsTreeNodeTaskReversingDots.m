classdef topsTreeNodeTaskReversingDots < topsTreeNodeTask
   % @class topsTreeNodeTaskReversingDots
   %
   % Reversing dots (RD) task
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskReversingDots.getStandardConfiguration
   %
   % Otherwise:
   %  1. Create an instance directly:
   %        task = topsTreeNodeTaskReversingDots();
   %
   %  2. Set properties. These are required:
   %        task.screenEnsemble
   %        task.helpers.readers.theObject
   %     Others can use defaults
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 8/17/19 created by jig
   
   properties % (SetObservable)
      
      % Trial properties.
      %
      % Set useQuest to a handle to a topsTreeNodeTaskRTDots to use it
      %     to get coherences
      settings = struct( ...
         'useQuest',                   [],   ...
         'valsFromQuest',              [],   ... % % cor vals on pmf to get
         'targetDistance',             8,    ...
         'dotsSeedBase',               randi(9999), ...
         'reversalSet',                [0.3 0.6 0.9], ... % if reversal<-1
         'reversalType',               'time'); % 'time' or 'hazard'; see prepareDrawables
      
      % Timing properties, referenced in statelist
      timing = struct( ...
         'fixationTimeout',           5.0,   ...
         'holdFixation',              0.5,   ...
         'duration',                  [0.2 0.5 1.0], ... % min mean max
         'finalEpochDuration',        [],    ...
         'minEpochDuration',          0.1,   ...
         'maxEpochDuration',          5.0,   ...
         'minimumRT',                 0.05,  ...
         'showFeedback',              1.0,   ...
         'interTrialInterval',        1.0,   ...
         'preDots',                   [0.1 0.3 0.6], ...
         'dotsTimeout',               5.0,   ...
         'choiceTimeout',             3.0);
      
      % Fields below are optional but if found with the given names
      %  will be used to automatically configure the task
      
      % Array of structures of independent variables, used by makeTrials
      independentVariables = struct( ...
         'direction',      struct('values', [0 180],  'priors', []), ...
         'coherence',      struct('values', 90,       'priors', []), ...
         'reversal',       struct('values', [0.2 0.5],      'priors', []), ...
         'duration',       struct('values', 1.0,      'priors', []), ...
         'finalDuration',  struct('values', [],       'priors', []));
         
      % dataFieldNames are used to set up the trialData structure
      trialDataFields = {'RT', 'choice', 'correct', ...
         'direction', 'coherence', 'randSeedBase', 'fixationOn', ...
         'fixationStart', 'targetOn', 'dotsOn', 'finalCPTime', 'dotsOff', ...
         'choiceTime', 'targetOff', 'fixationOff', 'feedbackOn'};
      
      % Drawables settings
      drawable = struct( ...
         ...
         ...   % Stimulus ensemble and settings
         'stimulusEnsemble',           struct( ...
         ...
         ...   % Fixation drawable settings
         'fixation',                   struct( ...
         'fevalable',                  @dotsDrawableTargets, ...
         'settings',                   struct( ...
         'xCenter',                    0,                ...
         'yCenter',                    0,                ...
         'nSides',                     4,                ...
         'width',                      1.0.*[1.0 0.1],   ...
         'height',                     1.0.*[0.1 1.0],   ...
         'colors',                     [1 1 1])),        ...
         ...
         ...   % Targets drawable settings
         'targets',                    struct( ...
         'fevalable',                  @dotsDrawableTargets, ...
         'settings',                   struct( ...
         'nSides',                     100,              ...
         'width',                      1.5.*[1 1],       ...
         'height',                     1.5.*[1 1])),      ...
         ...
         ...   % Dots drawable settings
         'dots',                       struct( ...
         'fevalable',                  @dotsDrawableDotKinetogram, ...
         'settings',                   struct( ...
         'xCenter',                    0,                ...
         'yCenter',                    0,                ...
         'coherenceSTD',               10,               ...
         'stencilNumber',              1,                ...
         'pixelSize',                  5,                ...
         'diameter',                   10,                ...
         'density',                    180,              ...
         'speed',                      3))));
      
      % Readable settings
      readable = struct( ...
         ...
         ...   % The readable object
         'reader',                    	struct( ...
         ...
         'copySpecs',                  struct( ...
         ...
         ...   % The gaze windows
         'dotsReadableEye',            struct( ...
         'bindingNames',               'stimulusEnsemble', ...
         'prepare',                    {{@updateGazeWindows}}, ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'breakFixation', 'choseLeft', 'choseRight'}, ...
         'ensemble',                   {'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble'}, ... % ensemble object to bind to
         'ensembleIndices',            {[1 1], [1 1], [2 1], [2 2]})}}), ...
         ...
         ...   % The keyboard events .. 'uiType' is used to conditionally use these depending on the theObject type
         'dotsReadableHIDKeyboard',    struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',                  {'KeyboardSpacebar', 'KeyboardF', 'KeyboardJ'}, ...
         'isRelease',                  {true, false, false})}}), ...
         ...
         ...   % Gamepad
         'dotsReadableHIDGamepad',     struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',                  {'Button1', 'Trigger1', 'Trigger2'}, ...
         'isRelease',                  {true, false, false})}}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy',          struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',                  {'Dummy1', 'Dummy2', 'Dummy3'})}}))));
      
      % Feedback messages
      message = struct( ...
         ...
         'message',                    struct( ...
         ...
         ...   Instructions
         'Instructions',               struct( ...
         'text',                       {{'Indicate the final dot direction', 'Good luck!'}}, ...
         'duration',                   1, ...
         'pauseDuration',              0.5, ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Correct
         'Correct',                    struct(  ...
         'text',                       {{'Correct', 'y', 6}}, ...
         'images',                     {{'thumbsUp.jpg', 'y', -6}}, ...
         ...%'playable',                   'cashRegister.wav', ...
         'bgStart',                    [0 0.6 0], ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Error
         'Error',                      struct(  ...
         'text',                       'Error', ...
         ...%'playable',                   'buzzer.wav', ...
         'bgStart',                    [0.6 0 0], ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   No choice
         'No_choice',                  struct(  ...
         'text',                       'No choice - please try again!')));
   end
   
   properties (SetAccess = protected)
      
      % Check for changes in properties that require drawables to be
      %  recomputed
      targetDistance;
      
      % Reversal directions/times -- precomputed for each trial and then executed.
      reversals = struct('directions', [], 'plannedTimes', [], 'actualTimes', []);
      
      % Keep track of reversals
      nextReversal;
      
      % indices for drawable objects
      fpIndex;
      targetIndex;
      dotsIndex;
   end
   
   methods
      
      %% Constuctor
      %  Use topsTreeNodeTask method, which can parse the argument list
      %  that can set properties (even those nested in structs)
      function self = topsTreeNodeTaskReversingDots(varargin)
         
         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(varargin{:});
      end
      
      %% Start task (overloaded)
      %
      % Put stuff here that you want to do before each time you run this
      % task
      function startTask(self)
         
         if ~isempty(self.settings.useQuest)
            
            % Update independent variable struct using Quest threshold
            self.independentVariables.coherence.values = ...
               self.settings.useQuest.getQuestThreshold( ...
               self.settings.valsFromQuest);
         end
         
         % ---- Get some useful indices
         %
         fn               = fieldnames(self.drawable.stimulusEnsemble);
         self.fpIndex     = find(strcmp('fixation', fn));
         self.targetIndex = find(strcmp('targets', fn));
         self.dotsIndex   = find(strcmp('dots', fn));
         
         % ---- Initialize the state machine
         %
         self.initializeStateMachine();
         
         % ---- Show task-specific instructions
         %
         self.helpers.message.show('Instructions');
       end
      
      %% Finish task (overloaded)
      %
      % Put stuff here that you want to do after each time you run this
      % task
      function finishTask(self)
      end
      
      %% Start trial
      %
      % Put stuff here that you want to do before each time you run a trial
      function startTrial(self)
         
         % ---- Prepare components
         %
         self.prepareDrawables();

         % ---- Use the task ITI
         %
         self.interTrialInterval = self.timing.interTrialInterval;

         % ---- Show information about the task/trial
         %
         % Task information
         taskString = sprintf('%s (task %d/%d): %d correct, %d error, mean RT=%.2f', ...
            self.name, self.taskID, length(self.caller.children), ...
            sum([self.trialData.correct]==1), sum([self.trialData.correct]==0), ...
            nanmean([self.trialData.RT]));
         
         % Trial information
         trial = self.getTrial();
         if ~isempty(self.reversals)
            numReversals = length(self.reversals.plannedTimes)-1;
         else
            numReversals = 0;
         end
         trialString = sprintf('Trial %d/%d, coh=%.0f, dur=%.2f, nflips=%d', ...
            self.trialCount, numel(self.trialData), trial.coherence, ...
            trial.duration, numReversals);
         
         % Show the information on the GUI
         self.updateStatus(taskString, trialString); % just update the second one
      end
      
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)         
      end
      
      %% Check for flip
      %
      %
      function next = checkForReversal(self)
         
         % For now, never return anything
         next = '';
         
         % Make sure we're reversing
         if isempty(self.nextReversal)
            return
         end
                  
         % Get the trial for timing info
         trial = self.getTrial();
                     
         % Check for reversal
         if feval(self.clockFunction) - trial.trialStart - trial.dotsOn >= ...
               self.reversals.plannedTimes(self.nextReversal)
                           
            % Reverse!
            %
            % Set the direction
            eh = self.helpers.stimulusEnsemble;
            eh.theObject.setObjectProperty('direction', self.reversals.directions(self.nextReversal), ...
               self.dotsIndex);
            
            % Explicitly flip here so we can get the timestamp
            frameInfo = eh.theObject.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            
            % Save the time in SCREEN time
            self.reversals.actualTimes(self.nextReversal) = ...
               eh.getSynchronizedTime(frameInfo.onsetTime, true) - trial.dotsOn;
            
            % For debugging
            disp(sprintf('FLIPPED to %d at time: %.2f planned, %.2f actual', ...
               self.reversals.directions(self.nextReversal), ...
               self.reversals.plannedTimes(self.nextReversal), ...
               self.reversals.actualTimes(self.nextReversal)))
            
            % update the counter
            self.nextReversal = self.nextReversal + 1;
            if self.nextReversal > length(self.reversals.plannedTimes)
               self.nextReversal = [];
            end
         end
      end
            
      %% Check for choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function nextState = checkForChoice(self, events, eventTag, nextStateAfterChoice)
         
         % ---- Check for event
         %
         eventName = self.helpers.reader.readEvent(events, self, eventTag);
         
         % Default return
         nextState = [];
         
         % Nothing... keep checking
         if isempty(eventName)
            return
         end
         
         % Get current task/trial
         trial = self.getTrial();
         
         % Check for minimum RT, wrt dotsOn for RT, dotsOff for non-RT
         RT = trial.choiceTime - trial.dotsOff;
         if RT < self.timing.minimumRT
            return
         end

         % ---- Good choice!
         %
         % Override completedTrial flag
         self.completedTrial = true;
         
         % Jump to next state when done
         nextState = nextStateAfterChoice;
         
         % Save the choice
         trial.choice = double(strcmp(eventName, 'choseRight'));
         
         % Mark as correct/error
         trial.correct = double( ...
            (trial.choice==0 && cosd(trial.direction)<0) || ...
            (trial.choice==1 && cosd(trial.direction)>0));
         
         % Save RT
         trial.RT = RT;
         
         % Store the reversal times
         topsDataLog.logDataInGroup(self.reversals, 'ReversingDotsReversals');
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);
      end
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % Get current task/trial
         trial = self.getTrial();
         
         % Get feedback message group
         if trial.correct == 1
            messageGroup = 'Correct';
         elseif trial.correct == 0
            messageGroup = 'Error';
         else
            messageGroup = 'No_choice';
         end         
         
         % --- Show trial feedback in GUI/text window
         %
         trialString = ...
            sprintf('Trial %d/%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData), ...
            messageGroup, trial.RT);
         self.updateStatus([], trialString); % just update the second one
         
         % ---- Show trial feedback on the screen
         %
         self.helpers.message.show(messageGroup);
      end
   end
      
   methods (Access = protected)
      
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % ---- Get the current trial and other useful stuff, and set
         %        values
         %
         trial = self.getTrial();

         % Set the seed base for the random number generator
         trial.randSeedBase = self.settings.dotsSeedBase; 
         
         % Set the dots duration if not already given in trial struct
         if ~isfinite(trial.duration)
            trial.duration = self.timing.duration; % Set the dots duration
         end
         
         % Funny value in case we want to control timing after final
         % change-point            
         if ~isfinite(trial.finalDuration) 
            trial.finalDuration = self.timing.finalEpochDuration;
         end      
      
         % ---- Compute reversal times, start/final directions
         %
         % Defaults -- no flippy!
         self.reversals    = [];
         self.nextReversal = [];
         startDirection    = trial.direction;

         % Use trial.reversal property
         if trial.reversal ~= 0
            
            % Setting up reversals array
            switch(self.settings.reversalType)
               case 'hazard'
                  
                  % Interpret "reversal" as fixed hazard rate.
                  [plannedTimes, trial.duration] = ...
                     computeChangePoints(trial.reversal, ...
                     self.timing.minEpochDuration, ...
                     self.timing.maxEpochDuration, ...
                     trial.duration, ...
                     trial.finalDuration);
                                    
               otherwise % case 'time'
                  
                  % Special case -- check if trial.reversal < 0 ... if so,
                  % that's just a flag saying to use the set
                  if trial.reversal < 0
                     plannedTimes = self.settings.reversalSet;
                  else
                     plannedTimes = trial.reversal;
                  end
                  
                  % Strip unnecessary values
                  plannedTimes = plannedTimes(plannedTimes<trial.duration);
            end
            
            % Check that we have reversals
            numReversals = length(plannedTimes);
            if numReversals > 0
               
               % Set up reversals struct, with one entry per direction epoch
               otherDirection = setdiff(self.independentVariables.direction.values, trial.direction);
               self.reversals.directions = repmat(trial.direction, 1, numReversals+1);
               self.reversals.directions(end:-2:1) = otherDirection;
               self.reversals.plannedTimes = [0 plannedTimes];
               self.reversals.actualTimes  = [0 nans(1, numReversals)];
               self.nextReversal           = 2;
               startDirection              = self.reversals.directions(1);
               trial.direction             = self.reversals.directions(end);
            end
         end         
         
         % Set the dots duration in the statelist
         self.stateMachine.editStateByName('showDots', 'timeout', trial.duration);
         
         % ---- Possibly update all stimulusEnsemble objects if settings
         %        changed
         %
         ensemble = self.helpers.stimulusEnsemble.theObject;
         td       = self.settings.targetDistance;
         if isempty(self.targetDistance) || self.targetDistance ~= td
            
            % Save current value(s)
            self.targetDistance = self.settings.targetDistance;
            
            %  Get target locations relative to fp location
            fpX = ensemble.getObjectProperty('xCenter', self.fpIndex);
            fpY = ensemble.getObjectProperty('yCenter', self.fpIndex);
            
            %  Now set the target x,y
            ensemble.setObjectProperty('xCenter', [fpX - td, fpX + td], self.targetIndex);
            ensemble.setObjectProperty('yCenter', [fpY fpY], self.targetIndex);
         end
         
         % ---- Save dots properties
         %
         ensemble.setObjectProperty('randBase',  trial.randSeedBase, self.dotsIndex);
         ensemble.setObjectProperty('coherence', trial.coherence,    self.dotsIndex);
         ensemble.setObjectProperty('direction', startDirection,     self.dotsIndex);
         
         % ---- Prepare to draw dots stimulus
         %
         ensemble.callObjectMethod(@prepareToDrawInWindow);
         
         % ---- Save the trial
         self.setTrial(trial);
      end
      
      %% Initialize StateMachine
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks  = {@dotsTheScreen.blankScreen};
         chkuif  = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
         chkuib  = {}; % {@getNextEvent, self.readables.theObject, false, {}}; % {'brokeFixation'}
         chkuic  = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choiceTime', 'blank'};
         chkrev  = {@checkForReversal, self};
         showfx  = {@draw, self.helpers.stimulusEnsemble, {self.fpIndex, [self.targetIndex self.dotsIndex]},  self, 'fixationOn'};
         showt   = {@draw, self.helpers.stimulusEnsemble, {self.targetIndex, []}, self, 'targetOn'};
         showfb  = {@showFeedback, self};
         showd   = {@draw,self.helpers.stimulusEnsemble, {self.dotsIndex, []}, self, 'dotsOn'};
         hided   = {@draw,self.helpers.stimulusEnsemble, {[], [self.fpIndex self.dotsIndex]}, self, 'dotsOff'};
         
         % drift correction
         hfdc  = {@reset, self.helpers.reader.theObject, true};
         
         % Activate/deactivate readable events
         sea   = @setEventsActiveFlag;
         gwfxw = {sea, self.helpers.reader.theObject, 'holdFixation', 'all'};
         gwfxh = {};
         gwts  = {sea, self.helpers.reader.theObject, {'choseLeft', 'choseRight'}, 'holdFixation'};
         
         % ---- Timing variables, read directly from the timing property struct
         %
         t = self.timing;
         
         % ---- Make the state machine. These will be added into the
         %        stateMachine (in topsTreeNode)
         %
         states = {...
            'name'              'entry'  'input'  'timeout'          'exit'     'next'            ; ...
            'showFixation'      showfx   {}       0                     {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   t.fixationTimeout     {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   t.holdFixation        hfdc    'showTargets'     ; ...
            'showTargets'       showt    chkuib   t.preDots             gwts    'preDots'         ; ...
            'preDots'           {}       {}       0                     {}      'showDots'        ; ...
            'showDots'          showd    chkrev   0                     hided   'waitForChoice'   ; ...
            'waitForChoice'     {}       chkuic   t.choiceTimeout       {}      'blank'           ; ...
            'blank'             {}       {}       0.2                   blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       t.showFeedback        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0                     blanks  'done'            ; ...
            'done'              {}       {}       0                     {}      ''                ; ...
            };
         
         % Set up the state list with automatic drawing/fipping of the 
         %  objects in stimulusEnsemble in the given list of states
         self.addStateMachineWithDrawing(states, ...
            'stimulusEnsemble', {'preDots' 'showDots'});
         
         % Turn on state debug flag
         % self.debugStates();
      end
   end
   
   methods (Static)
      
      %% ---- Utility for defining standard configurations
      %
      % name is string
      function task = getStandardConfiguration(name, varargin)
         
         % ---- Get the task object, with optional property/value pairs
         %
         task = topsTreeNodeTaskReversingDots(name, varargin{:});
      end
      
      %% ---- Utility for getting test configuration
      %
      function task = getTestConfiguration()
         
         task = topsTreeNodeTaskReversingDots();
         task.timing.minimumRT = 0.3;
         task.message.message.Instructions.text = {'Testing', 'topsTreeNodeTaskRTDots'};
      end
   end
end
