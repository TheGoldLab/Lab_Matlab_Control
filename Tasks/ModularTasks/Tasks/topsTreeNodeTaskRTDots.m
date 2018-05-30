classdef topsTreeNodeTaskRTDots < topsTreeNodeTask
   % @class topsTreeNodeTaskRTDots
   %
   % Response-time dots (RTD) task
   %
   % Typically you would:
   %
   %  1. Create an instance:
   %        task = topsTreeNodeTaskRTDots()
   %  2. Set properties, in particular typically you need to provide:
   %        task.screenEnsemble
   %        task.textEnsemble
   %        task.keyboard
   %        task.userInput
   %  3. Configure the task
   %        task.configure();
   %  4. Add this as a child to another topsTreeNode
   %
   % 5/28/18 created by jig
   
   properties
      
      % Trial properties. Note: can set coherences = 'Quest'
      trialProperties = struct( ...
         'trialsPerCoherence', 10, ...
         'directions',         [0 180], ...
         'coherences',         [0 3.2 6.4 12.8 25.6 51.2], ...
         'directionPriors',    [50 50], ...
         'targetDistance',     10);
      
      % The fixation point
      fixationProperties = struct( ...
         'xCenter',        0, ...
         'yCenter',        0, ...
         'width',          1.0.*[1.0 0.1], ...
         'height',         1.0.*[0.1 1.0], ...
         'colors',         [1 1 1]);
      
      % The targets
      targetsProperties = struct( ...
         'width',          1.5.*[1 1], ...
         'height',         1.5.*[1 1]);
      
      % The dots stimulus
      dotsProperties = struct( ...
         'xCenter',        0, ...
         'yCenter',        0, ...
         'stencilNumber',  1, ...
         'pixelSize',      6, ...
         'diameter',       8, ...
         'density',        150, ...
         'speed',          3);
      
      % The text object used for feedback (can be given separately)
       textProperties = struct( ...
         'textOffset',        5);
           
      % Task timing, all in sec
      timing = struct( ...
         'showInstructions',         3.0, ...
         'waitAfterInstructions',    0.5, ...
         'fixationTimeout',          5.0, ...
         'holdFixation',             0.5, ...
         'showFeedback',             1.0, ...
         'InterTrialInterval',       1.0, ...
         'showTargetForeperiodMin',  0.2, ...
         'showTargetForeperiodMax',  1.0, ...
         'showTargetForeperiodMean', 0.5, ...
         'dotsTimeout',              5.0);
      
      % Default user input. For now can be:
      %  'dotsReadableEyePupilLabs'
      %  'dotsReadableEyeMouseSimulator'
      %  'dotsReadableHIDKeyboard'
      defaultUserInput = 'dotsReadableHIDKeyboard';
      
      % Information to set up gaze windows if the userInput device is a
      % dotsReadableEye
      % columns are:
      %  1. Window name
      %  2. Event name
      %  3. Graphical object indices ([object item]) where the window is centered
      gazeWindows = { ...
         'fixWindow',  'holdFixation', [1 1]; ...
         'trg1Window', 'choseLeft',    [2 1]; ...
         'trg2Window', 'choseRight',   [2 2]};
      
      % Sizes and durations of the gaze windows. Note that we use the first
      % three characters as a tag to know which ones to set
      fixWindowSize  = 5;
      fixWindowDur   = 0.2;
      trgWindowSize  = 5;
      trgWindowDur   = 0.2;
      
      % Keyboard event to trigger dotsReadableEye.calibrate()
      calibrationEvent = { ...
         'KeyboardC', 'calibrate'};
      
      % Information to set up keyboard events if the userInput device is a
      % dotsReadableHIDKeyboard
      keyboardEvents = { ...
         'KeyboardSpacebar',  'holdFixation'; ...
         'KeyboardF',         'choseLeft'; ...
         'KeyboardJ',         'choseRight'};
      
      % Information to set up default keyboard events
      % Columns are:
      %  1. Keyboard item name
      %  2. Event name (triggered when pressed)
      defaultKeyboardEvents = { ...
         'KeyboardQ',   'quit'; ...
         'KeyboardP',   'pause'; ...
         'KeyboardD',   'done'; ...
         'KeyboardS',   'skip'};
      
      % Instruction strings to show at the beginning of the task
      instructionStrings = { ...
         'Be as fast and accurate as possible', ...
         'BOTH directions equally likely'};
      
      % Quest properties
      questProperties = struct( ...
         'stimRange',         0:100, ...
         'thresholdRange',    0:50, ...
         'slopeRange',        2:5, ...
         'guessRate',         0.5, ...
         'lapseRange',        0.00:0.01:0.05);
      
      % Information for sending TTLs at the beginning of each trial
      sendTTLs = false;
      
      % The screen ensemble. Normally this should be given after construction.
      screenEnsemble = [];
      
      % The dotsDrawableText ensemble used for instructions and feedback.
      % This might be given from elsewhere
      textEnsemble = [];
      
      % The keyboard device. This is always used for flow-control commands
      % given between trials, even if this is not the primary userInput
      % device
      keyboard = [];
      
      % references to topsGroupedList holding coherence, RT referents that
      % are updated by Quest
      groupList = [];
      
      % coherence ref tags {<group>, <tag>}
      coherenceRef = {};
      
      % RT ref tags {<group>, <tag>}
      RTRef = {};      
   end
   
   properties (SetAccess = protected)
      
      % The stimulus ensemble, defined by the properties above.
      stimulusEnsemble = [];
      
      % The state machine, created locally
      stateMachine = [];
      
      % The state machine concurrent composite, created locally
      stateMachineComposite = [];
      
      % Quest object from mQUESTplus
      quest = [];      
   end
   
   methods
      
      %% Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTaskRTDots(varargin)
         self = self@topsTreeNodeTask(varargin{:});
      end
      
      %% Configuration method
      function configure(self)
         
         % Do these separately for readability
         self.configureDrawables();
         self.configureReadables();
         self.configureTrials();
         self.configureStateMachine();         
      end
      
      %% Overloaded start task method
      function start(self)
         
         % Do some bookkeeping
         self.start@topsRunnable();
         
         % ---- Set the keyboard events
         %
         % First deactivate all events
         self.keyboard.deactivateEvents();
         
         % Now add given events. Note that the third and fourth arguments
         % are Calibrated value and isActive -- could make those user
         % controlled
         for ii = 1:size(self.defaultKeyboardEvents,1)
            self.keyboard.defineCalibratedEvent( ...
               self.defaultKeyboardEvents{ii,1}, ...
               self.defaultKeyboardEvents{ii,2}, ...
               1, true);
         end
         
         % ---- Set the userInput events
         %
         %  Here we need to case on the kind of userInput object
         if isa(self.userInput, 'dotsReadableEye')
            
            % For eye trackers, set gaze windows
            %
            % First clear existing
            self.userInput.clearCompoundEvents();
            
            % Want to keep recording during re-centering
            self.userInput.recordDuringCalibration = true;
            
            % Now set up new ones
            for ii = 1:size(self.gazeWindows, 2)
               
               % Get the name
               name = self.gazeWindows{ii,1};
               
               % Get the x,y position from the stimulusEnsemble
               x = self.stimulusEnsemble.getObjectProperty('xCenter', ...
                  self.gazeWindows{ii,3}(1));  
               x = x(self.gazeWindows{ii,3}(2));
               y = self.stimulusEnsemble.getObjectProperty('yCenter', ...
                  self.gazeWindows{ii,3}(1));
               y = y(self.gazeWindows{ii,3}(2));
               
               % Use the name to get the size/duration
               winSize = self.([name(1:3) 'WindowSize']);
               winDur  = self.([name(1:3) 'WindowDur']);

               self.userInput.defineCompoundEvent( ...
                  name, ...
                  'eventName',   self.gazeWindows{ii,2}, ...
                  'centerXY',    [x y], ...
                  'windowSize',  winSize, ...
                  'windowDur',   winDur);
            end
            
            % Now set the keyboard calibration event
            self.keyboard.defineCalibratedEvent(self.calibrationEvent{1}, ...
               self.calibrationEvent{2}, 1, true);
            
         elseif isa(self.userInput, 'dotsReadableHIDKeyboard')
            
            % Use keyboard input
            for ii = 1:size(self.keyboardEvents,1)
               self.keyboard.defineCalibratedEvent( ...
                  self.keyboardEvents{ii,1}, ...
                  self.keyboardEvents{ii,2}, ...
                  1, true);
            end
         end
         
         % ---- Show task-specific instructions
         %
         if ~isempty(self.instructionStrings{1}) || ...
               ~isempty(self.instructionStrings{1})
            
            % Call utility function
            drawTextEnsemble( ...
               self.textEnsemble, ...
               self.instructionStrings, ...
               self.timing.showInstructions);
            
            % Wait
            pause(self.timing.waitAfterInstructions);
         end
         
         % Get the first trial
         self.setNextTrial();
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
         
         % Get the current trial
         trial = self.getTrial();
         
         % ---- Set dots properties
         %
         % Possibly use reference coherence (e.g., from Quest)
         if ~isfinite(trial.coherence)
            trial.coherence = ...
               self.groupList{self.coherenceRef{1}}{self.coherenceRef{2}};
         end
         
         % Save the coherence and direction to the dots object
         %  in the stimulus ensemble
         self.stimulusEnsemble.setObjectProperty('coherence', trial.coherence, 3);
         self.stimulusEnsemble.setObjectProperty('direction', trial.direction, 3);
         
         % Prepare to draw dots stimulus
         self.stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow);
         
         % ---- Set the targets foreperiod
         %
         % Randomly sample a duration from an exponential distribution with bounds
         self.stateMachine.editStateByName('showTargets', 'timeout', ...
            self.timing.showTargetForeperiodMin + ...
            min(exprnd(self.timing.showTargetForeperiodMean), ...
            self.timing.showTargetForeperiodMax));
         
         % ---- Show information about the task/trial
         %
         disp(' ');
         disp(sprintf('%s (%d/%d): trial %d of %d, dir=%d, coh=%.1f', ...
            self.name, self.taskID, length(self.caller.children), ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence))
         
         % ---- Flush the UI and deactivate all compound events (gaze windows)
         %
         self.keyboard.flushData();
         self.userInput.flushData();
         self.userInput.deactivateCompoundEvents();
         
         % ---- Save times
         %
         [trial.time_local_trialStart, trial.time_screen_trialStart, ...
            trial.time_screen_roundTrip, trial.time_ui_trialStart] = ...
            syncTiming(self.screenEnsemble, self.userInput);
         
         % ---- Conditionally send TTL pulses
         %
         if self.sendTTLs
            
            % Send TTLs mod trial count
            [trial.time_TTLStart, trial.time_TTLFinish] = ...
               sendTTLsequence(mod(self.trialCount,4)+1);
         end
         
         % Re-save the trial
         self.setTrial(trial);
      end
      
      %% Finish trial method
      function finishTrial(self)
         
         % Get the current trial
         trial = self.getTrial();
         
         % ---- Save times
         %
         [trial.time_local_trialFinish, trial.time_screen_trialFinish, ...
            ~, trial.time_ui_trialFinish] = ...
            syncTiming(self.screenEnsemble, self.userInput);
         
         % Re-save the trial
         self.setTrial(trial);
         
         % ---- Save the current trial in the DataLog
         %
         %  We do this even if no choice was made, in case later we want
         %     to re-parse the UI data
         topsDataLog.logDataInGroup(trial, 'trial');
         
         % ---- Update to the next trial.
         %
         %  Argument is a flag indicating whether or not to repeat the trial
         self.setNextTrial(trial.correct<0)
      end
      
      %% Set Choice method
      %
      % Save choice/RT information and set up feedback for the dots task
      function setDotsChoice(self, value)
         
         % ---- Get current task/trial and save the choice
         trial = self.getTrial();
         trial.choice = value;
         
         % ---- Parse choice info
         if value<0
            
            % NO CHOICE
            %
            % Set feedback for no choice
            feedbackString = 'No choice';
            
         else
            
            % GOOD CHOICE
            %
            % Mark as correct/error
            trial.correct = double( ...
               (trial.choice==0 && trial.direction==180) || ...
               (trial.choice==1 && trial.direction==0));
            
            % Compute/save RT
            %  Remember that dotsOn time might be from the remote computer, whereas
            %  sacOn is from the local computer, so we need to account for clock
            %  differences
            trial.RT = (trial.time_choice - trial.time_local_trialStart) - ...
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
               RTRefValue = self.groupList{self.RTRef{1}}{self.RTRef{2}};
               if isfinite(RTRefValue)
                  if trial.RT <= RTRefValue
                     feedbackString = cat(2, feedbackString, ', in time');
                  else
                     feedbackString = cat(2, feedbackString, ', too slow');
                  end
               end
            end
         end
         
         % ---- Re-save the trial
         self.setTrial(trial);
         
         % ---- Set the feedback string
         self.textEnsemble.setObjectProperty('string', feedbackString, 1);
         
         % --- Print feedback in the command window
         disp(sprintf('  %s, RT=%.2f (%d correct, %d error, mean RT=%.2f)', ...
            feedbackString, trial.RT, ...
            sum([self.trialData.correct]==1), ...
            sum([self.trialData.correct]==0), ...
            nanmean([self.trialData.RT])))
      end
      
      %% updateQuest method
      %
      function updateQuest(self)
         
         % check for bad trial
         previousTrial = self.getTrial(self.trialCount-1);
         if isempty(previousTrial) || previousTrial.choice < 0
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
         if psiParamsQuest(1) > 0
            val = psiParamsQuest(1);
         end
         self.groupList{self.coherenceRef{1}}{self.coherenceRef{2}} = val;
         
         % Update reference RT ... could do this by picking only
         % most-recent trials but for now using all
         self.groupList{self.RTRef{1}}{self.RTRef{2}} = ...
            nanmedian([self.trialData.RT]);
      end
   end
   
   methods (Access = private)
      
      
      %% Configure drawables
      %
      function configureDrawables(self)
         
         % ---- Configure the screen
         %
         if isempty(self.screenEnsemble)
            
            % just set up a debug screen
            screen = dotsTheScreen.theObject();
            screen.displayIndex = 0;
            self.screenEnsemble = dotsEnsembleUtilities.makeEnsemble('screenEnsemble', false);
            self.screenEnsemble.addObject(screen);
            self.screenEnsemble.automateObjectMethod('flip', @nextFrame);
         end
         
         % ---- Configure the graphics objects
         %
         % Create a stimulus ensemble consisting of three objects:
         %  1. Fixation cue
         fixation = dotsDrawableTargets();
         fixation.nSides  = 4;
         for ff = fieldnames(self.fixationProperties)'
            fixation.(ff{:}) = self.fixationProperties.(ff{:});
         end
         
         %  2. Two targets (left and right)
         targets = dotsDrawableTargets();
         targets.nSides = 100;
         for ff = fieldnames(self.targetsProperties)'
            targets.(ff{:}) = self.targetsProperties.(ff{:});
         end
         targets.xCenter = [ ...
            fixation.xCenter-self.trialProperties.targetDistance ...
            fixation.xCenter+self.trialProperties.targetDistance];
         targets.yCenter = fixation.yCenter.*[1 1];
         
         %  3. Random-dot stimulus
         dots = dotsDrawableDotKinetogram();
         for ff = fieldnames(self.dotsProperties)'
            dots.(ff{:}) = self.dotsProperties.(ff{:});
         end
         
         % create the ensemble
         self.stimulusEnsemble = makeDrawableEnsemble( ...
            'RTDots', {fixation, targets, dots}, self.screenEnsemble);
         
         % Automate drawing (for dots)
         self.stimulusEnsemble.automateObjectMethod('draw', @mayDrawNow);
         
         % ---- Configure the text ensemble
         %
         if isempty(self.textEnsemble)
            
            % Make two text objects
            self.textEnsemble = makeTextEnsemble('text', 2, ...
               self.textProperties.textOffset, self.screenEnsemble);
         end
      end
      
      %% Configure user input devices  
      %
      % Here we just make sure we have them ... don't actually configure
      % anything until the start() method
      function configureReadables(self)
         
         % ---- Configure the keyboard
         %
         if isempty(self.keyboard)
            self.keyboard = DBSmatchingKeyboard();
         end
         
         % ---- Configure the primary user input device
         %
         if isempty(self.userInput)
            self.userInput = eval(self.defaultUserInput);
         end
      end
      
      %% configureTrials method
      %
      function configureTrials(self)
         
         % check for special case of Quest
         if strcmp(self.trialProperties.coherences, 'Quest')
            
            % Initialize and save Quest object
            self.quest = qpInitialize(qpParams( ...
               'stimParamsDomainList', { ...
               self.questProperties.stimRange}, ...
               'psiParamsDomainList',  { ...
               self.questProperties.thresholdRange, ...
               self.questProperties.slopeRange, ...
               self.questProperties.guessRate, ...
               self.questProperties.lapseRange}));
            
            % Collect information to make trials
            cohs = min(100, max(0, qpQuery(self.quest)));
            
            % Make a quest callList to update quest status between trials
            questCallList = topsCallList('questCallList');
            questCallList.alwaysRunning = false;
            questCallList.addCall({@updateQuest, self}, 'update');
            self.addChild(questCallList);
         else
            
            % Use the given coherences
            cohs = self.trialProperties.coherences;
         end
         
         % Make array of directions, scaled by priors and num trials
         directionPriors = self.trialProperties.directionPriors./...
            (sum(self.trialProperties.directionPriors));
         directionArray = cat(1, ...
            repmat(self.trialProperties.directions(1), ...
            round(directionPriors(1).*self.trialProperties.trialsPerCoherence), 1), ...
            repmat(self.trialProperties.directions(2), ...
            round(directionPriors(2).*self.trialProperties.trialsPerCoherence), 1));
         
         % Make grid of directions, coherences
         [directionGrid, coherenceGrid] = meshgrid(directionArray, cohs);
         
         % Add structure array to the task's trialData
         % See getTaskDefaultDotsTrialData for details
         self.trialData = dealMat2Struct(self.trialData(1), ...
            'trialIndex', 1:numel(directionGrid), ...
            'direction', directionGrid(:)', ...
            'coherence', coherenceGrid(:)');
      end
      
      %% configureStateMachine method
      %
      function configureStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks = {@callObjectMethod, self.screenEnsemble, @blank};
         chkuif = {@getNextEvent, self.userInput, false, {'holdFixation'}};
         chkuib = {};%{@getNextEvent, self.userInput, false, {'brokeFixation'}};
         chkuic = {@getAndSaveNextEvent, self, {'choseLeft' 'choseRight'}, 'choice'};
         chkkbd = {@getNextEvent self.keyboard, false, {'done' 'pause' 'calibrate' 'skip' 'quit'}};
         showfx = {@setVisible, self, self.stimulusEnsemble, 1, 2:3, 'fixOn'};
         showt  = {@setVisible, self, self.stimulusEnsemble, 2, [], 'targsOn'};
         showd  = {@setVisible, self, self.stimulusEnsemble, 3, [], 'dotsOn'};
         hided  = {@setVisible, self, self.stimulusEnsemble, [], [1 3], 'dotsOff'};
         showfb = {@setVisible, self, self.textEnsemble, 1, [], 'fdbkOn'};
         abrt   = {@abort, self, true};
         skip   = {@abort, self};
         calpl  = {@calibrate, self.userInput};
         sch    = @(x)cat(2, {@setDotsChoice, self}, x);
         dce    = @defineCompoundEvent;
         gwfxw  = {dce, self.userInput, {'fixWindow', ...
            'eventName', 'holdFixation', 'isInverted', false, 'isActive', true}};
         gwfxh  = {dce, self.userInput, {'fixWindow', ...
            'eventName', 'brokeFixation', 'isInverted', true}};
         gwts   = {dce, self.userInput, {'fixWindow', 'isActive', false}, ...
            {'trg1Window', 'isActive', true}, {'trg2Window', 'isActive', true}};
         caleye = {@calibrate, self.userInput, 'recenter'};
            
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
            'waitForFixation'   gwfxw    chkuif   tft        caleye  'blankNoFeedback' ; ...
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
            'done'              {}       chkkbd   iti        {}      ''                ; ...
            'pause'             {}       chkkbd   inf        {}      ''                ; ...
            'calibrate'         calpl    {}       0          {}      ''                ; ...
            'skip'              skip     {}       0          {}      ''                ; ...
            'quit'              abrt     {}       0          {}      ''                ; ...
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
         activeList = {{self.stimulusEnsemble, 'draw'; self.screenEnsemble, 'flip'}, ...
            {'preDots' 'showDots'}};
         self.stateMachine.addSharedFevalableWithName( ...
            {@activateEnsemblesByState activeList}, 'activateEnsembles', 'entry');
         
         % ---- Make a concurrent composite to interleave run calls
         %
         self.stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
         self.stateMachineComposite.addChild(self.stateMachine);
         self.stateMachineComposite.addChild(self.stimulusEnsemble);
         self.stateMachineComposite.addChild(self.screenEnsemble);
         
         % Add it as a child to the task
         self.addChild(self.stateMachineComposite);
      end      
   end
end
