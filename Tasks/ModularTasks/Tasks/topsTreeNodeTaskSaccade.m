classdef topsTreeNodeTaskSaccade < topsTreeNodeTask
   % @class topsTreeNodeTaskSaccade
   %
   % Visually and Memory guided saccade tasks
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
         'trialsPerDirection', 10, ...
         'directions',         0:45:315, ...
         'targetDistance',     8);
      
      % The fixation point
      fixationProperties = struct( ...
         'xCenter',           0, ...
         'yCenter',           0, ...
         'width',             1.5.*[1.0 0.2], ...
         'height',            1.5.*[0.2 1.0], ...
         'colors',            [1 0 0]);
      
      % The target
      targetProperties = struct( ...
         'xCenter',           0, ...
         'yCenter',           0, ...
         'width',             1.5, ...
         'height',            1.5);
      
      % y-offset for the two default text objects
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
         'VGSTargetDuration',        1.0, ...
         'MGSTargetDuration',        0.25, ...
         'MGSDelayDuration',         0.75, ...
         'saccadeTimeout',           5.0);
      
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
      %  3. Graphical object index where the window is centered
      gazeWindows = { ...
         'fixWindow', 'holdFixation', [1 1]; ...
         'trgWindow', 'choseTarget',  [2 1]};
      
      % Sizes and durations of the gaze windows. Note that we use the first
      % three characters as a tag to know which ones to set
      fixWindowSize  = 4;
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
         'KeyboardT',         'choseTarget'};
      
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
         'When the fixation spot disappears', ...
         'Look at the visual target'};
      
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
   end
   
   properties (SetAccess = protected)
      
      % The stimulus ensemble, defined by the properties above.
      stimulusEnsemble = [];
      
      % The state machine, created locally
      stateMachine = [];
      
      % The state machine concurrent composite, created locally
      stateMachineComposite = [];      
   end
   
   methods
      
      %% Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTaskSaccade(varargin)
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
            for ii = 1:size(self.gazeWindows, 1)
               
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
            self.keyboard.defineCalibratedEvent( ...
                self.calibrationEvent{1}, ...
                self.calibrationEvent{2}, ...
                1, true);
            
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
         
         % ---- Prepare saccade task
         %
         % Turn on t1 only, set location
         
         % Get x,y location of center of target
         targetOffset = self.trialProperties.targetDistance;
         x = self.fixationProperties.xCenter + targetOffset * cosd(trial.direction);
         y = self.fixationProperties.yCenter + targetOffset * sind(trial.direction);
         self.stimulusEnsemble.setObjectProperty('xCenter', x, 2);
         self.stimulusEnsemble.setObjectProperty('yCenter', y, 2);
         
         % Update gaze window
         self.userInput.defineCompoundEvent('trgWindow', 'centerXY', [x y]);
         
         % Update stateMachine to jump to VGS-/MGS- specific states
         editStateByName(self.stateMachine, 'holdFixation', 'next', ...
            [self.name 'showTarget']);
         
         % ---- Show information about the task/trial
         %
         disp(' ');
         disp(sprintf('%s (%d/%d): trial %d of %d, dir=%d', ...
            self.name, self.taskID, length(self.caller.children), ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction))
         
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
      % Save choice/RT information and set up feedback
      function setSaccadeChoice(self, value)
         
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
            % Set feedback
            feedbackString = 'Correct';
            
            % Compute/save RT
            %  Remember that time_choice time is from the UI, whereas
            %    fixOff is from the remote computer, so we need to
            %    account for clock differences
            trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
               (trial.time_fixOff - trial.time_screen_trialStart);
         end

         % ---- Re-save the trial
         self.setTrial(trial);

         % ---- Set the feedback string
         self.textEnsemble.setObjectProperty('string', feedbackString, 1);

         % --- Print feedback in the command window
         disp(sprintf('  %s, RT=%.2f (mean RT=%.2f)', feedbackString, ...
            trial.RT, nanmean([self.trialData.RT])))
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
         % Create a stimulus ensemble consisting of two objects:
         %  1. Fixation cue
         fixation = dotsDrawableTargets();
         fixation.nSides  = 4;
         for ff = fieldnames(self.fixationProperties)'
            fixation.(ff{:}) = self.fixationProperties.(ff{:});
         end
         
         %  2. One target
         target = dotsDrawableTargets();
         target.nSides = 100;
         for ff = fieldnames(self.targetProperties)'
            target.(ff{:}) = self.targetProperties.(ff{:});
         end
         
         % create the ensemble
         self.stimulusEnsemble = makeDrawableEnsemble( ...
            'Saccade', {fixation, target}, self.screenEnsemble);
         
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
         
         % make array of directions
         directions = repmat(self.trialProperties.directions, ...
            self.trialProperties.trialsPerDirection, 1);
         self.trialData = dealMat2Struct(self.trialData(1), ...
            'trialIndex', 1:numel(directions), ...
            'direction', directions);
      end
      
      %% configureStateMachine method
      %
      function configureStateMachine(self)
                  
         % Fevalables for state list
         blanks = {@callObjectMethod, self.screenEnsemble, @blank};
         chkuif = {@getNextEvent, self.userInput, false, {'holdFixation'}};
         chkuib = {}; %{@getNextEvent, self.userInput, false, {'brokeFixation'}};
         chkuic = {@getAndSaveNextEvent, self, {'choseTarget'}, 'choice'};
         chkkbd = {@getNextEvent self.keyboard, false, {'done' 'pause' 'calibrate' 'skip' 'quit'}};
         showfx = {@setVisible, self, self.stimulusEnsemble, 1, 2, 'fixOn'};
         showt  = {@setVisible, self, self.stimulusEnsemble, 2, [], 'targsOn'};
         hidet  = {@setVisible, self, self.stimulusEnsemble, [], 2, 'targsOff'};
         hidefx = {@setVisible, self, self.stimulusEnsemble, [], 1, 'fixOff'};
         showfb = {@setVisible, self, self.textEnsemble, 1, [], 'fdbkOn'};
         abrt   = {@abort, self, true};
         skip   = {@abort, self};
         calpl  = {@calibrate, self.userInput};
         sch    = @(x)cat(2, {@setSaccadeChoice, self}, x);
         dce    = @defineCompoundEvent;
         gwfxw  = {dce, self.userInput, {'fixWindow', ...
             'eventName', 'holdFixation', 'isInverted', false, 'isActive', true}};
         gwfxh  = {dce, self.userInput, {'fixWindow', ...
             'eventName', 'brokeFixation', 'isInverted', true}};
         gwt    = {dce, self.userInput, {'fixWindow', 'isActive', false}, ...
             {'trgWindow', 'isActive', true}};
         caleye = {@calibrate, self.userInput, 'recenter'};

         % Timing variables
         tft = self.timing.fixationTimeout;
         tfh = self.timing.holdFixation;
         vtd = self.timing.VGSTargetDuration;
         mtd = self.timing.MGSTargetDuration;
         mdd = self.timing.MGSDelayDuration;
         sto = self.timing.saccadeTimeout;
         tsf = self.timing.showFeedback;
         iti = self.timing.InterTrialInterval;
         
         %% ---- Make the state machine
         %
         % Note that the startTrial routine sets the target location and the 'next'
         % state after holdFixation, based on VGS vs MGS task
         trialStates = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   tft        caleye  'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   tfh        {}      'showTarget'      ; ... % Branch here
            'VGSshowTarget'     showt    chkuib   vtd        gwt     'hideFix'         ; ... % VGS
            'MGSshowTarget'     showt    chkuib   mtd        {}      'MGSdelay'        ; ... % MGS
            'MGSdelay'          hidet    chkuib   mdd        gwt     'hideFix'         ; ...
            'hideFix'           hidefx   chkuic   sto        {}      'noChoice'        ; ...
            'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
            'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
            'choseTarget'       sch( 1)  {}       0          {}      'blank'           ; ...
            'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       tsf        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0          blanks  'done'            ; ...
            'done'              {}       chkkbd   iti        {}      ''                ; ...
            'pause'             {}       chkkbd   inf        {}      ''                ; ...
            'calibrate'         calpl    {}       0          {}      ''                ; ...
            'skip'              skip     {}       0          {}      ''                ; ...
            'quit'              abrt     {}       0          {}      ''                ; ...
            };
         
         %% ---- Put stuff together in a stateMachine so that it will run
         self.stateMachine = topsStateMachine();
         self.stateMachine.addMultipleStates(trialStates);
         self.stateMachine.startFevalable = {@self.startTrial};
         self.stateMachine.finishFevalable = {@self.finishTrial};
         
         % For debugging
         %self.stateMachine.addSharedFevalableWithName( ...
         %   {@showStateInfo}, 'debugStates', 'entry');
         
         %% ---- Make a concurrent composite to interleave run calls
         self.stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
         self.stateMachineComposite.addChild(self.stateMachine);
         
         % Add it as a child to the task
         self.addChild(self.stateMachineComposite);
      end      
   end
end
