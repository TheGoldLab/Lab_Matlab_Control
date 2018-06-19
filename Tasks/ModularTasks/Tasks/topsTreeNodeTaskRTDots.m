classdef topsTreeNodeTaskRTDots < topsTreeNodeTask
   % @class topsTreeNodeTaskRTDots
   %
   % Response-time dots (RTD) task
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskRTDots.getStandardConfiguration
   % 
   % Otherwise:
   %  1. Create an instance:
   %        task = topsTreeNodeTaskRTDots()
   %  2. Set properties, in particular typically you need to provide:
   %        task.drawables.screenEnsemble
   %        task.drawables.textEnsemble
   %        task.readables.userInput
   %  3. Add this as a child to another topsTreeNode
   %
   % 5/28/18 created by jig
   
   properties
      
      % Trial properties. 
      %  NOTE that coherences can have special values:
      %     'Quest' ... use adaptive method
      %     <topsTreeNodeTaskRTDots object> -- get coherences value there
      %           (e.g., from a Quest task)
      settings = struct( ...
         'trialsPerCoherence',            10, ...
         'directions',                    [0 180], ...
         'coherences',                    [0 3.2 6.4 12.8 25.6 51.2], ...
         'directionPriors',               [50 50], ...
         'referenceRT',                   [], ...
         'sendTTLs',                      false);
      
      % Timing properties
      timing = struct( ...
         'showInstructions',              10.0, ...
         'waitAfterInstructions',         0.5, ...
         'fixationTimeout',               5.0, ...
         'holdFixation',                  0.5, ...
         'showFeedback',                  1.0, ...
         'InterTrialInterval',            1.0, ...
         'showTargetForeperiodMin',       0.2, ...
         'showTargetForeperiodMax',       1.0, ...
         'showTargetForeperiodMean',      0.5, ...
         'dotsTimeout',                   5.0);
      
      % Drawables settings
      drawables = struct( ...
         ...
         ...   % Ensembles
         'screenEnsemble',                [],      ...
         'stimulusEnsemble',              [],      ...
         'textEnsemble',                  [],      ...
         ...
         ...   % General settings
         'settings',                   struct( ...
         'targetOffset',                  8,                ...
         'textOffset',                    2,                ...
         'textStrings',                   ''),               ...
         ...
         ...   % Fixation drawable settings
         'fixation',                   struct( ...
         'xCenter',                       0,                ...
         'yCenter',                       0,                ...
         'nSides',                        4,                ...
         'width',                         1.0.*[1.0 0.1],   ...
         'height',                        1.0.*[0.1 1.0],   ...
         'colors',                        [1 1 1]),         ...
         ...
         ...   % Targets drawable settings
         'targets',                    struct( ...
         'nSides',                        100,              ...
         'width',                         1.5.*[1 1],       ...
         'height',                        1.5.*[1 1]),      ...
         ...
         ...   % Dots drawable settings
         'dots',                       struct( ...
         'xCenter',                       0,                ...
         'yCenter',                       0,                ...
         'stencilNumber',                 1,                ...
         'pixelSize',                     6,                ...
         'diameter',                      8,                ...
         'density',                       150,              ...
         'speed',                         3));

      % Readable settings
      readables = struct( ...
         ...
         ...   % The readable object
         'userInput',                     [],               ...
         ...
         ...   % readable settings
         'settings',                   struct( ....
         'bufferGaze',                 false), ...
         ...
         ...   % The gaze windows
         'gazeWindows', struct( ...
         'name',           {'fixWindow', 'trg1Window', 'trg2Window'}, ...
         'eventName',      {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'windowSize',     {8, 8, 8}, ...
         'windowDur',      {0.15, 0.15, 0.15}, ...
         'objectIndices',  {[1 1], [2 1], [2 2]}), ...
         ...
         ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the userInput type
         'keyboardEvents', struct( ...
         'name',        {'KeyboardSpacebar', 'KeyboardF', 'KeyboardJ', 'KeyboardC'}, ...
         'eventName',   {'holdFixation', 'choseLeft', 'choseRight', 'calibrate'}));
      
      % Quest properties
      questSettings = struct( ...
         'stimRange',                     0:100,            ...
         'thresholdRange',                0:50,             ...
         'slopeRange',                    2:5,              ...
         'guessRate',                     0.5,              ...
         'lapseRange',                    0.00:0.01:0.05);
   end
   
   properties (SetAccess = protected)

      % Flag indicating whether to update drawables between trials; e.g.,
      % after a property value changed
      updateDrawables = true;
      
      % Flag indicating whether to update readables between trials; e.g.,
      % after a property value changed
      updateReadables = true;

      % The quest object
      quest = [];
      
      % The state machine, created locally
      stateMachine = [];
      
      % The state machine concurrent composite, created locally
      stateMachineComposite = [];
   end
   
   methods
      
      %% Constuctor
      %  Use topsTreeNodeTask method, which can parse the argument list
      %  that can set properties (even those nested in structs)
      function self = topsTreeNodeTaskRTDots(varargin)
         self = self@topsTreeNodeTask(varargin{:});
      end
      
      % Set method for drawables properties that updates the
      % updateDrawables flag
      function set.drawables(self, value)
         self.drawables = value;
         self.updateDrawables = true;
      end
      
      % Set method for readable properties that updates the
      % updateReadables flag
      function set.readables(self, value)
         self.readables = value;
         self.updateReadables = true;
      end
      
      %% Overloaded start task method
      function start(self)
         
         % Do some bookkeeping via superclass
         self.start@topsTreeNodeTask();
         
         % Check for abort
         if ~self.isRunning
            return
         end
         
         % Configure each element - separated into different methods for
         % readability
         self.initializeDrawables();
         self.initializeReadables();         
         self.initializeTrialData();
         self.initializeStateMachine();         
         
         % ---- Show task-specific instructions
         %
         drawTextEnsemble(self.drawables.textEnsemble, ...
            self.drawables.settings.textStrings, ...
            self.timing.showInstructions, ...
            self.timing.waitAfterInstructions);
         
         % Get the first trial
         self.prepareForNextTrial();
      end
      
      %% Overloaded finish task method
      function finish(self)
         
         % Do some bookkeeping
         self.finish@topsRunnable();
         
         % Write data from the log to disk
         topsDataLog.writeDataFile();
      end
      
      %% Start trial method
      function startTrial(self)
         
         % ---- Prepare components
         %
         self.prepareDrawables();
         self.prepareReadables();
         self.prepareStateMachine();
         self.prepareTrialData();

         % ---- Show information about the task/trial
         %
         trial = self.getTrial();
         self.statusStrings = { ...
            ... % Task info
            sprintf('%s (task %d/%d): %d correct, %d error, mean RT=%.2f', ...
            self.name, self.taskID, ...
            length(self.caller.children), ...
            sum([self.trialData.correct]==1), ...
            sum([self.trialData.correct]==0), ...
            nanmean([self.trialData.RT])), ...
            ... % Trial info
            sprintf('Trial %d/%d, dir=%d, coh=%d', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence)};
         self.updateStatus();
      end
      
      %% Finish trial method
      function finishTrial(self)
         
         % ---- Sync times again, just to be sure
         %
         trial = self.getTrial();
         [trial.time_local_trialFinish, ...
            trial.time_screen_trialFinish, ~, ...
            trial.time_ui_trialFinish] = ...
            syncTiming(self.drawables.screenEnsemble, ...
            self.readables.userInput);
          self.setTrial(trial);

         % ---- Save the current trial in the DataLog
         %
         %  We do this even if no choice was made, in case later we want
         %     to re-parse the UI data
         topsDataLog.logDataInGroup(trial, 'trial');
         
         % ---- Prepare for the next trial
         %
         % We do this here instead of in startTrial because prepareForNextTrial 
         % might terminate the task if no trials remain.
         self.prepareForNextTrial();
      end
      
      %% Set Choice method
      %
      % Save choice/RT information and set up feedback for the dots task
      function setDotsChoice(self, value)
         
         % ---- Get current task/trial and save the choice
         trial = self.getTrial();
         trial.correct = value;
         trial.choice = value;
         
         % ---- Parse choice info
         if value<0
            
            % NO CHOICE
            %
            % Set feedback for no choice, repeat trial
            feedbackString = 'No choice';
            
         else
            
            % GOOD CHOICE
            %
            % Override repeat trial flag
            self.repeatTrial = false;

            % Mark as correct/error
            trial.correct = double( ...
               (trial.choice==0 && trial.direction==180) || ...
               (trial.choice==1 && trial.direction==0));
            
            % Compute/save RT
            %  Remember that dotsOn time might be from the remote computer, whereas
            %  sacOn is from the local computer, so we need to account for clock
            %  differences
            trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
               (trial.time_dotsOn - trial.time_screen_trialStart);
            
            % Set up feedback string
            %  First Correct/error
            if trial.correct == 1
               feedbackString = 'Correct';
            else
               feedbackString = 'Error';
            end
            
            %  Second possibly feedback about speed
            if self.name(1) == 'S'
               
               % Check current RT relative to the reference value
               if isa(self.settings.referenceRT, 'topsTreeNodeTaskRTDots')
                  RTRefValue = self.settings.referenceRT.settings.referenceRT;
               else
                  RTRefValue = self.settings.referenceRT;
               end
               
               if isfinite(RTRefValue)
                  if trial.RT <= RTRefValue
                     feedbackString = cat(2, feedbackString, ', in time');
                  else
                     feedbackString = cat(2, feedbackString, ', try to decide faster');
                  end
               end
            end
         end
         
         % ---- Re-save the trial
         self.setTrial(trial);
                  
         % --- Show trial feedback
         self.statusStrings{2} = ...
            sprintf('Trial %d/%d, dir=%d, coh=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence, feedbackString, trial.RT);
         self.updateStatus(2); % just update the second one
         
         % ---- Set the feedback string
         self.drawables.textEnsemble.setObjectProperty('string', feedbackString, 1);
      end
      
      %% updateQuest method
      %
      function updateQuest(self)
         
         % check for bad trial
         previousTrial = self.getTrial(self.trialCount-1);
         if isempty(previousTrial) || previousTrial.correct < 0
            return
         end
         
         % Update Quest (expects 1=error, 2=correct)
         self.quest = qpUpdate(self.quest, previousTrial.coherence, ...
            previousTrial.correct + 1);
         
         % Update next guess, bounded between 0 and 100, if there is a next trial
         val = min(100, max(0, qpQuery(self.quest)));
         if self.trialCount > 0
            self.trialData(self.trialIndices(self.trialCount)).coherence = val;
         end
         
         % Set reference coherence to current threshold
         psiParamsIndex = qpListMaxArg(self.quest.posterior);
         psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:);
         if ~isempty(psiParamsQuest(1)) && psiParamsQuest(1) > 0
            val = psiParamsQuest(1);
         end
         
         % coherence ref/RT
         self.settings.coherences = val;
         self.settings.referenceRT = nanmedian([self.trialData.RT]);
      end
   end
   
   methods (Access = private)
           
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % Get the current trial
         trial = self.getTrial();
         
         % Possibly use reference coherence (e.g., from Quest)
         if isa(self.settings.coherences, 'topsTreeNodeTaskRTDots')
            trial.coherence = self.settings.coherences.settings.coherences;
            
            self.setTrial(trial);
         end

         % Save the coherence and direction to the dots object
         %  in the stimulus ensemble
         self.drawables.stimulusEnsemble.setObjectProperty('coherence', trial.coherence, 3);
         self.drawables.stimulusEnsemble.setObjectProperty('direction', trial.direction, 3);
         
         % possibly update all stimulusEnsemble objects
         if self.updateDrawables
            
            % Target locations
            %
            %  Determined relative to fp location
            fpX = self.drawables.stimulusEnsemble.getObjectProperty('xCenter', 1);
            fpY = self.drawables.stimulusEnsemble.getObjectProperty('yCenter', 1);
            
            %  Now set the target x,y
            self.drawables.stimulusEnsemble.setObjectProperty('xCenter', [...
               fpX - self.drawables.settings.targetDistance, ...
               fpX + self.drawables.settings.targetDistance], 2);
            self.drawables.stimulusEnsemble.setObjectProperty('yCenter', fpY.*[1 1], 2);
            
            % set updateReadables flag because gaze windows depend on
            % target positions
            self.updateReadables = true;            
            
            % All other stimulus ensemble properties
            stimulusDrawables = {'fixation' 'targets' 'dots'};
            for dd = 1:length(stimulusDrawables)
               for ff = fieldnames(self.drawables.(stimulusDrawables{dd}))'
                  self.drawables.stimulusEnsemble.setObjectProperty(ff{:}, ...
                     self.drawables.(stimulusDrawables{dd}).(ff{:}), dd);
               end
            end
            
            % reset flag
            self.updateDrawables = false;
         end
         
         % Prepare to draw dots stimulus
         self.drawables.stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow);
      end
      
       %% Prepare readables for this trial
      %
      function prepareReadables(self)
         
         % Check for keyboard update
         if isa(self.readables.userInput, 'dotsReadableHIDKeyboard') && ...
               self.updateReadables
            
            % ---- set keyboard events
            %
            % First deactivate all events
            self.readables.userInput.deactivateEvents();
            
            % Now add given events. Note that the third and fourth arguments
            %  to defineCalibratedEvent are Calibrated value and isActive --
            %  we could make those user controlled.
            for ii = 1:length(self.readables.keyboardEvents)
               self.readables.userInput.defineCalibratedEvent( ...
                  self.readables.keyboardEvents(ii).name, ...
                  self.readables.keyboardEvents(ii).eventName, ...
                  1, true);
            end
            
         elseif isa(self.readables.userInput, 'dotsReadableEye')
            
            % ---- Get target x,y positions
            %
            xs = self.drawables.stimulusEnsemble.getObjectProperty('xCenter');
            ys = self.drawables.stimulusEnsemble.getObjectProperty('yCenter');
            
            % ---- Control gaze buffering
            %
            % Arguments are useBuffer and recenter
            self.readables.userInput.resetGaze(false);
            
            % Then conditionally turn it on when re-centering at fp x,y
            editStateByName(self.stateMachine, 'holdFixation', 'exit', ...
               {@resetGaze, self.readables.userInput, ...
               self.readables.settings.bufferGaze, [xs{1} ys{1}]});
            
            % ---- Conditionally set gazeWindows
            %
            % Check for reset
            if self.updateReadables
               
               % First clear existing
               self.readables.userInput.clearCompoundEvents();
               
               % Now set up new ones
               for ii = 1:length(self.readables.gazeWindows)
                  
                  % Define the event
                  gw = self.readables.gazeWindows(ii);
                  oi = gw.objectIndices;
                  self.readables.userInput.defineCompoundEvent( ...
                     self.readables.gazeWindows(ii).name, ...
                     'eventName',   gw.eventName, ...
                     'centerXY',    [xs{oi(1)}(oi(2)) ys{oi(1)}(oi(2))], ...
                     'windowSize',  gw.windowSize, ...
                     'windowDur',   gw.windowDur);
               end
            end
         end           
         
         % ---- Unset the flag
         %
         self.updateReadables = false;         
         
         % ---- Flush the UI and deactivate all compound events (gaze windows)
         %
         self.readables.userInput.flushData();
         self.readables.userInput.deactivateCompoundEvents();
      end
      
      %% Prepare trialData for this trial
      %
      function prepareTrialData(self)
         
         % ---- Get the current trial
         trial = self.getTrial();
         
         % ---- Set repeat flag, which must be overridden
         self.repeatTrial = true;
         
         % ---- Get synchronization times
         %
         [trial.time_local_trialStart, ...
            trial.time_screen_trialStart, ...
            trial.time_screen_roundTrip, ...
            trial.time_ui_trialStart] = ...
            syncTiming(self.drawables.screenEnsemble, ...
            self.readables.userInput);
         
         % Conditionally send TTL pulses (mod trial count)
         if self.settings.sendTTLs
            [trial.time_TTLStart, trial.time_TTLFinish] = ...
               sendTTLsequence(mod(self.trialCount,4)+1);
         end
         
         % ---- Re-save the trial
         self.setTrial(trial);
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)
         
         % Set the targets foreperiod
         %
         % Randomly sample a duration from an exponential distribution with bounds
         self.stateMachine.editStateByName('showTargets', 'timeout', ...
            self.timing.showTargetForeperiodMin + ...
            min(exprnd(self.timing.showTargetForeperiodMean), ...
            self.timing.showTargetForeperiodMax));
      end
      
      %% Initialize Drawables
      %
      % Create the three ensembles (if not given):
      %  screenEnsemble
      %  stimulusEnsemble
      %  textEnsemble
      function initializeDrawables(self)
      
         % Make the screen ensemble
         if isempty(self.drawables.screenEnsemble)
            
            % just set up a debug screen
            screen = dotsTheScreen.theObject();
            screen.displayIndex = 0;
            self.drawables.screenEnsemble = dotsEnsembleUtilities.makeEnsemble('screenEnsemble', false);
            self.drawables.screenEnsemble.addObject(screen);
            self.drawables.screenEnsemble.automateObjectMethod('flip', @nextFrame);
         end
         
         % Make the stimulus ensemble
         %  
         % Three objects:
         %  1. Fixation cue
         %  2. Two targets (left and right)
         %  3. Random-dot stimulus
         if isempty(self.drawables.stimulusEnsemble)
            
            % create the ensemble
            self.drawables.stimulusEnsemble = makeDrawableEnsemble('RTDots', ...
               {dotsDrawableTargets(), dotsDrawableTargets(), dotsDrawableDotKinetogram}, ...
               self.drawables.screenEnsemble);
            
            % Automate drawing (for dots)
            self.drawables.stimulusEnsemble.automateObjectMethod('draw', @mayDrawNow);
         end

         % Make the text ensemble
         %
         % Two text objects
         if isempty(self.drawables.textEnsemble)    
            
            % Create the ensemble
            self.drawables.textEnsemble = makeTextEnsemble('text', 2, ...
               self.drawables.settings.textOffset, self.drawables.screenEnsemble);
         end
      end
      
      %% Initialize Readables
      %
      % Create the two readables (if not given)
      function initializeReadables(self)

         % Set user input device -- default to keyboard
         if isempty(self.readables.userInput)
            self.readables.userInput = dotsReadableHIDKeyboard();
         end
      end
      
      %% Initialize TrialData
      %
      function initializeTrialData(self)
         
         % check for special case of Quest
         if strcmp(self.name, 'Quest')
            
            % Initialize and save Quest object
            self.quest = qpInitialize(qpParams( ...
               'stimParamsDomainList', { ...
               self.questSettings.stimRange}, ...
               'psiParamsDomainList',  { ...
               self.questSettings.thresholdRange, ...
               self.questSettings.slopeRange, ...
               self.questSettings.guessRate, ...
               self.questSettings.lapseRange}));
            
            % Collect information to make trials
            cohs = min(100, max(0, qpQuery(self.quest)));
            self.settings.coherences = cohs;
            
            % Make a quest callList to update quest status between trials
            questCallList = topsCallList('questCallList');
            questCallList.alwaysRunning = false;
            questCallList.addCall({@updateQuest, self}, 'update');
            self.addChild(questCallList);
            
         elseif isa(self.settings.coherences, 'topsTreeNodeTaskRTDots')
            
            % Use nans but set to ref object at run-time
            cohs = nan;
            
         else
            
            % Use the given coherences
            cohs = self.settings.coherences;
         end
         
         % Make array of directions, scaled by priors and num trials
         directionPriors = self.settings.directionPriors./...
            (sum(self.settings.directionPriors));
         directionArray = cat(1, ...
            repmat(self.settings.directions(1), ...
            round(directionPriors(1).*self.settings.trialsPerCoherence), 1), ...
            repmat(self.settings.directions(2), ...
            round(directionPriors(2).*self.settings.trialsPerCoherence), 1));
         
         % Make grid of directions, coherences
         [directionGrid, coherenceGrid] = meshgrid(directionArray, cohs);
         
         % Fill in the trialData with relevant information
         self.trialData = dealMat2Struct(self.trialData(1), ...
            'taskID', repmat(self.taskTypeID,1,numel(directionGrid)), ...
            'trialIndex', 1:numel(directionGrid), ...
            'direction', directionGrid(:)', ...
            'coherence', coherenceGrid(:)');
      end
      
      %% Initialize StateMachine
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks = {@callObjectMethod, self.drawables.screenEnsemble, @blank};
         chkuif = {@getNextEvent, self.readables.userInput, false, {'holdFixation'}};
         chkuib = {};%{@getNextEvent, self.userInput, false, {'brokeFixation'}};
         chkuic = {@getEventWithTimestamp, self, self.readables.userInput, {'choseLeft' 'choseRight'}, 'choice'};
         showfx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 1, 2:3, 'fixOn'};
         showt  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         showd  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 3, [], 'dotsOn'};
         hided  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], [1 3], 'dotsOff'};
         showfb = {@drawWithTimestamp, self, self.drawables.textEnsemble, 1, [], 'fdbkOn'};
         pse    = {@pause 0.005};
         sch    = @(x)cat(2, {@setDotsChoice, self}, x);
         dce    = @defineCompoundEvent;
         gwfxw  = {dce, self.readables.userInput, {'fixWindow', ...
            'eventName', 'holdFixation', 'isInverted', false, 'isActive', true}};
         gwfxh  = {dce, self.readables.userInput, {'fixWindow', ...
            'eventName', 'brokeFixation', 'isInverted', true}};
         gwts   = {dce, self.readables.userInput, {'fixWindow', 'isActive', false}, ...
            {'trg1Window', 'isActive', true}, {'trg2Window', 'isActive', true}};
            
         % ---- Timing variables
         %
         tft = self.timing.fixationTimeout;
         tfh = self.timing.holdFixation;
         dtt = self.timing.dotsTimeout;
         tsf = self.timing.showFeedback;
         iti = self.timing.InterTrialInterval;
         
         % ---- Make the state machine
         %
         trialStates = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   tfh        {}      'showTargets'     ; ...
            'showTargets'       showt    chkuib   1          gwts    'preDots'         ; ...
            'preDots'           {}       {}       0          {}      'showDots'        ; ...
            'showDots'          showd    chkuic   dtt        hided   'noChoice'        ; ...
            'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
            'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
            'choseLeft'         sch( 0)  {}       0          {}      'blank'           ; ...
            'choseRight'        sch( 1)  {}       0          {}      'blank'           ; ...
            'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       tsf        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0          blanks  'done'            ; ...
            'done'              pse      {}       iti        {}      ''                ; ...
            };
         
         % ---- Put stuff together in a stateMachine so that it will run
         %
         self.stateMachine = topsStateMachine();
         self.stateMachine.addMultipleStates(trialStates);
         self.stateMachine.startFevalable = {@self.startTrial};
         self.stateMachine.finishFevalable = {@self.finishTrial};
         
         % ---- Set up ensemble activation list.
         %
         % See activateEnsemblesByState for details.
         % Note that the predots state is what allows us to get a good timestamp
         %   of the dots onset... we start the flipping before, so the dots will start
         %   as soon as we send the isVisible command in the entry fevalable of showDots
         activeList = {{self.drawables.stimulusEnsemble, 'draw'; self.drawables.screenEnsemble, 'flip'}, ...
            {'preDots' 'showDots'}};
         self.stateMachine.addSharedFevalableWithName( ...
            {@activateEnsemblesByState activeList}, 'activateEnsembles', 'entry');
         
         % ---- Make a concurrent composite to interleave run calls
         %
         self.stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
         self.stateMachineComposite.addChild(self.stateMachine);
         self.stateMachineComposite.addChild(self.drawables.stimulusEnsemble);
         self.stateMachineComposite.addChild(self.drawables.screenEnsemble);
         
         % Add it as a child to the task
         %
         self.addChild(self.stateMachineComposite);
      end      
   end
   
   methods (Static)

      %% ---- Utility for defining standard configurations
      %
      % name is string:
      %  'Quest' for adaptive threshold procedure
      %  or '<SAT><BIAS>' tag, where:
      %     <SAT> is 'N' for neutral, 'S' for speed, 'A' for accuracy
      %     <BIAS> is 'N' for neutral, 'L' for left more likely, 'R' for
      %     right more likely
      function task = getStandardConfiguration(name, trialsPerCoherence, varargin)
                  
         % Get the task object, with optional property/value pairs
         task = topsTreeNodeTaskRTDots(name, varargin{:});
         
         % Set block size
         if ~isempty(trialsPerCoherence)
            task.settings.trialsPerCoherence = trialsPerCoherence;
         end
         
         % Instruction settings, by column:
         %  1. tag (first character of name)
         %  2. Text string #1
         %  3. RTFeedback flag
         SATsettings = { ...
            'S' 'Be as fast as possible'                 task.settings.referenceRT; ...
            'A' 'Be as accurate as possible'             nan;...
            'N' 'Be as fast and accurate as possible'    nan};
         
         dp = task.settings.directionPriors;
         BIASsettings = { ...
            'L' 'LEFT is more likely'                    [max(dp) min(dp)]; ...
            'R' 'RIGHT is more likely'                   [min(dp) max(dp)]; ...
            'N' 'BOTH directions equally likely'         [50 50]};
         
         % For instructions
         if strcmp(name, 'Quest')
            name = 'NN';
         end
         
         % Set strings, priors based on type
         Lsat  = strcmp(name(1), SATsettings(:,1));
         Lbias = strcmp(name(2), BIASsettings(:,1));
         task.drawables.settings.textStrings = ...
            {SATsettings{Lsat, 2}, BIASsettings{Lbias, 2}};
         task.settings.referenceRT     = SATsettings{Lsat, 3};
         task.settings.directionPriors = BIASsettings{Lbias, 3};
      end
   end
end
