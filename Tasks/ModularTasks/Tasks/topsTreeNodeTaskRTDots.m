classdef topsTreeNodeTaskRTDots < topsTreeNodeTask
   % @class topsTreeNodeTaskRTDots
   %
   % Response-time dots (RTD) task
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskRTDots.getStandardConfiguration
   % 
   % Otherwise:
   %  1. Create an instance directly:
   %        task = topsTreeNodeTaskRTDots();
   %
   %  2. Set properties. These are required:
   %        task.screenEnsemble
   %        task.readables.userInput
   %     Others can use defaults
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 5/28/18 created by jig
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties. 
      %  NOTE that certain properties can have special values:
      %  -- coherences:
      %     'Quest' ... use adaptive method
      %     <topsTreeNodeTaskRTDots object> -- get coherences value there
      %           (e.g., from a Quest task)
      %  -- dotsDuration:
      %     [] (default) ... RT task
      %     [val] ... use given fixed value
      %     [min mean max] ... specify as pick from exponential distribution
      settings = struct( ...
         'trialsPerCoherence',            10, ...
         'directions',                    [0 180], ...
         'coherences',                    [0 3.2 6.4 12.8 25.6 51.2], ...
         'directionPriors',               [50 50], ...
         'dotsDuration',                  [], ...
         'referenceRT',                   []);
      
      % Timing properties
      timing = struct( ...
         'showInstructions',              10.0, ...
         'waitAfterInstructions',         0.5, ...
         'fixationTimeout',               5.0, ...
         'holdFixation',                  0.5, ...
         'showFeedback',                  1.0, ...
         'InterTrialInterval',            1.0, ...
         'showTargetForeperiod',          [0.2 0.5 1.0], ...
         'dotsTimeout',                   5.0);
      
      % Drawables settings
      drawables = struct( ...
         ...
         ...   % Ensembles
         'stimulusEnsemble',              [],      ...
         'textEnsemble',                  [],      ...
         ...
         ...   % General settings
         'settings',                   struct( ...
         'fixationRTDim',                 0.4,              ...
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
         'settings',                   struct(              ...
         'bufferGaze',                 false),              ...
         ...
         ...   % The gaze windows
         'dotsReadableEye', struct( ...
         'name',              {'holdFixation', 'breakFixation', 'choseLeft', 'choseRight'}, ...
         'isInverted',        {false, true, false, false}, ...
         'windowSize',        {8, 8, 8, 8}, ...
         'windowDur',         {0.15, 0.15, 0.15, 0.15}, ...
         'ensemble',          {[], [], [], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [1 1], [2 1], [2 2]}), ... % object/item indices
         ...
         ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the userInput type
         'dotsReadableHIDKeyboard', struct( ...
         'name',              {'holdFixation', 'choseLeft', 'choseRight', 'calibrate'}, ...
         'component',         {'KeyboardSpacebar', 'KeyboardF', 'KeyboardJ', 'KeyboardC'}));
      
      % Quest properties
      questSettings = struct( ...
         'stimRange',                     0:100,            ...
         'thresholdRange',                0:50,             ...
         'slopeRange',                    2:5,              ...
         'guessRate',                     0.5,              ...
         'lapseRange',                    0.00:0.01:0.05);
   end
   
   properties (SetAccess = protected)

      % The quest object
      quest = [];
      
      % Boolean flag, whether an RT task or not
      isRT = [];
   end
   
   methods
      
      %% Constuctor
      %  Use topsTreeNodeTask method, which can parse the argument list
      %  that can set properties (even those nested in structs)
      function self = topsTreeNodeTaskRTDots(varargin)

         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(varargin{:});
         
         % ---- Keep track of changes to certain property structs
         %
         %  This will eventually be useful for real-time updating
         self.registerSetListeners('drawables', 'readables');
      end

      %% Start task (overloaded)
      % 
      % Put stuff here that you want to do before each time you run this
      % task
      function startTask(self)
         
         % ---- Configure each element - separated into different methods for
         % readability
         %
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
         self.prepareReadables();
         self.prepareStateMachine();

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
            
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
      end
      
      %% Set Choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function setDotsChoice(self, value)
         
         % ---- Get current task/trial and save the choice
         %
         trial = self.getTrial();
         trial.correct = value;
         trial.choice  = value;
         
         % ---- Parse choice info
         %
         if value<0
            
            % NO CHOICE
            %
            % Set feedback for no choice, repeat trial
            feedbackString = 'No choice';
            
         else
            
            % GOOD CHOICE
            %
            % Override completedTrial flag
            self.completedTrial = true;

            % Mark as correct/error
            trial.correct = double( ...
               (trial.choice==0 && trial.direction==180) || ...
               (trial.choice==1 && trial.direction==0));
            
            % Compute/save RT
            %  Remember that dotsOn time might be from the remote computer, whereas
            %  sacOn is from the local computer, so we need to account for clock
            %  differences
            if self.isRT
               % RT trial, compute wrt dots on
               trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
                  (trial.time_dotsOn - trial.time_screen_trialStart);
            else
               % non-RT trial, compute wrt dots off
               trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
                  (trial.time_dotsOff - trial.time_screen_trialStart);
            end
            
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
         %
         self.setTrial(trial);
                  
         % --- Show trial feedback
         %
         self.statusStrings{2} = ...
            sprintf('Trial %d/%d, dir=%d, coh=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence, feedbackString, trial.RT);
         self.updateStatus(2); % just update the second one
         
         % ---- Set the feedback string
         %
         self.drawables.textEnsemble.setObjectProperty('string', feedbackString, 1);
      end
      
      %% updateQuest
      %
      function updateQuest(self)
         
         % ---- check for bad trial
         %
         previousTrial = self.getTrial(self.trialCount-1);
         if isempty(previousTrial) || previousTrial.correct < 0
            return
         end
         
         % ---- Update Quest 
         %
         % (expects 1=error, 2=correct)
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
         
         %  ---- Set coherence ref/RT
         %
         self.settings.coherences = val;
         self.settings.referenceRT = nanmedian([self.trialData.RT]);
      end
   end
   
   methods (Access = private)
           
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % ---- Get the current trial
         % 
         trial = self.getTrial();
         
         % ---- Possibly update all stimulusEnsemble objects
         %
         if self.updateFlags.drawables
            
            % Target locations
            %
            %  Determined relative to fp location
            fpX = self.drawables.stimulusEnsemble.getObjectProperty('xCenter', 1);
            fpY = self.drawables.stimulusEnsemble.getObjectProperty('yCenter', 1);
            
            %  Now set the target x,y
            self.drawables.stimulusEnsemble.setObjectProperty('xCenter', [...
               fpX - self.drawables.settings.targetDistance, ...
               fpX + self.drawables.settings.targetDistance], 2);
            self.drawables.stimulusEnsemble.setObjectProperty('yCenter', ...
               fpY.*[1 1], 2);
            
            % All other stimulus ensemble properties
            stimulusDrawables = {'fixation' 'targets' 'dots'};
            for dd = 1:length(stimulusDrawables)
               for ff = fieldnames(self.drawables.(stimulusDrawables{dd}))'
                  self.drawables.stimulusEnsemble.setObjectProperty(ff{:}, ...
                     self.drawables.(stimulusDrawables{dd}).(ff{:}), dd);
               end
            end
            
            % set updateReadables flag because gaze windows depend on
            % target positions, but not drawables
            self.updateFlags.readables = true;
            self.updateFlags.drawables = false;
         end
         
         % ---- Possibly use reference coherence (e.g., from Quest)
         % 
         if isa(self.settings.coherences, 'topsTreeNodeTaskRTDots')
            trial.coherence = self.settings.coherences.settings.coherences;            
            self.setTrial(trial);
         end

         % ---- Save the coherence and direction to the dots object
         %        in the stimulus ensemble
         %
         self.drawables.stimulusEnsemble.setObjectProperty('coherence', trial.coherence, 3);
         self.drawables.stimulusEnsemble.setObjectProperty('direction', trial.direction, 3);
         
         % ---- Prepare to draw dots stimulus
         %
         self.drawables.stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow);
      end
      
       %% Prepare readables for this trial
      %
      function prepareReadables(self)
         
         % ---- Reset the events for the given ui type
         %
         if self.updateFlags.readables
            
            % parse the name
            classType = intersect(fieldnames(self.readables), ...
               cat(1, class(self.readables.userInput), ...
               superclasses(self.readables.userInput)));
            
            % use it to call defineEvents with the appropriate event definitions
            self.readables.userInput.defineEvents(self.readables.(classType{:}));

            % reset flag
            self.updateFlags.readables = false;
         end
                  
         % ---- Deactivate the events (they are activated in the statelist)
         %     and flush the UI
         %
         self.readables.userInput.deactivateEvents();
         self.readables.userInput.flushData();
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)

         % ---- Set RT/deadline
         %
         self.isRT = isempty(self.settings.dotsDuration);
      end
      
      %% Initialize Drawables
      %
      % Create the three ensembles (if not given):
      %  screenEnsemble
      %  stimulusEnsemble
      %  textEnsemble
      function initializeDrawables(self)
      
         % ---- Check for screen
         %
         if isempty(self.screenEnsemble)
            error('topsTreeNodeTaskRTDots: missing screenEnsemble');
         end
         
         % ---- Make the stimulus ensemble
         %  
         % Three objects:
         %  1. Fixation cue
         %  2. Two targets (left and right)
         %  3. Random-dot stimulus
         if isempty(self.drawables.stimulusEnsemble)
            
            % create the ensemble
            self.drawables.stimulusEnsemble = makeDrawableEnsemble('RTDots', ...
               {dotsDrawableTargets(), dotsDrawableTargets(), dotsDrawableDotKinetogram}, ...
               self.screenEnsemble, true);
         end

         % ---- Make the text ensemble
         %
         % Two text objects
         if isempty(self.drawables.textEnsemble)    
            
            % Create the ensemble
            self.drawables.textEnsemble = makeTextEnsemble('text', 2, ...
               self.drawables.settings.textOffset, self.screenEnsemble);
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.drawables = true;
      end
      
      %% Initialize Readables
      %
      % Create the two readables (if not given)
      function initializeReadables(self)

         % ---- Set user input device: default to keyboard
         %
         if isempty(self.readables.userInput)
            self.readables.userInput = dotsReadableHIDKeyboard();
         end
         
         % ---- Bind stimulus ensemble to gaze windows
         %
         if isa(self.readables.userInput, 'dotsReadableEye')
            [self.readables.dotsReadableEye.ensemble] = ...
               deal(self.drawables.stimulusEnsemble);
         end
         
         % ---- Register the readable (for timing)
         %
         self.registerReadableTiming(self.readables.userInput);
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.readables = true;
      end
      
      %% Initialize TrialData
      %
      function initializeTrialData(self)
         
         % ---- Check for special case of Quest
         %
         % Otherwise get coherences
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
         
         % ---- Make array of directions, scaled by priors and num trials
         %
         directionPriors = self.settings.directionPriors./...
            (sum(self.settings.directionPriors));
         directionArray = cat(1, ...
            repmat(self.settings.directions(1), ...
            round(directionPriors(1).*self.settings.trialsPerCoherence), 1), ...
            repmat(self.settings.directions(2), ...
            round(directionPriors(2).*self.settings.trialsPerCoherence), 1));
         
         % ---- Make grid of directions, coherences
         %
         [directionGrid, coherenceGrid] = meshgrid(directionArray, cohs);
         
         % ---- Fill in the trialData with relevant information
         %
         self.trialData = dealMat2Struct(self.trialData(1), ...
            'taskID',      repmat(self.taskTypeID,1,numel(directionGrid)), ...
            'trialIndex',  1:numel(directionGrid), ...
            'direction',   directionGrid(:)', ...
            'coherence',   coherenceGrid(:)');
      end
      
      %% Initialize StateMachine
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks  = {@callObjectMethod, self.screenEnsemble, @blank};
         chkuif  = {@getNextEvent, self.readables.userInput, false, {'holdFixation'}};
         chkuib  = {}; % {@getNextEvent, self.readables.userInput, false, {}}; % {'brokeFixation'}
         chkuic  = {@getEventWithTimestamp, self, self.readables.userInput, {'choseLeft' 'choseRight'}, 'choice'};
         showfx  = {@setAndDrawWithTimestamp, self, self.drawables.stimulusEnsemble, ...
            {{'colors', [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, 2:3}}, 'fixOn'};
         showt   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         showfb  = {@drawWithTimestamp, self, self.drawables.textEnsemble, 1, [], 'fdbkOn'};
         showdRT = {@setAndDrawWithTimestamp, self, self.drawables.stimulusEnsemble, ...
            {{'colors', self.drawables.settings.fixationRTDim.*[1 1 1], 1}, {'isVisible', true, 3}}, 'dotsOn'};
         showdFX = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 3, [], 'dotsOn'};
         hided   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], [1 3], 'dotsOff'};
         pdbr    = {@setNextState, self, 'isRT', 'preDots', 'showDotsRT', 'showDotsFX'};
         pse     = {@pause 0.005};
         sch     = @(x)cat(2, {@setDotsChoice, self}, x);

         % drift correction
         hfdc  = {@reset, self.readables.userInput, true};
         
         % Activate/deactivate readable events
         dce   = @setEventsActiveFlag;
         gwfxw = {dce, self.readables.userInput, 'holdFixation'};
         gwfxh = {}; 
         gwts  = {dce, self.readables.userInput, {'choseLeft', 'choseRight'}, 'holdFixation'};
         % gwfxh = {}; % {dce, self.readables.userInput, 'brokeFixation', 'holdFixation'};
         % gwts  = {dce, self.readables.userInput, {'choseLeft', 'choseRight'}, 'brokeFixation'};
         
         % ---- Timing variables
         %
         tft = self.timing.fixationTimeout;
         tfh = self.timing.holdFixation;
         txp = {@sampleTime, self.timing.showTargetForeperiod};
         dtt = self.timing.dotsTimeout;
         dxp = {@sampleTime, self.settings.dotsDuration};
         tsf = self.timing.showFeedback;
         iti = self.timing.InterTrialInterval;         
         
         % ---- Make the state machine. These will be added into the 
         %        stateMachine (in topsTreeNode)
         %
         self.stateMachineStates = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          pdbr    'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   tfh        hfdc    'showTargets'     ; ...
            'showTargets'       showt    chkuib   txp        gwts    'preDots'         ; ...
            'preDots'           {}       {}       0          {}      ''                ; ...
            'showDotsRT'        showdRT  chkuic   dtt        hided   'noChoice'        ; ...
            'showDotsFX'        showdFX  {}       dxp        hided   'waitForChoiceFX' ; ...
            'waitForChoiceFX'   {}       chkuic   dtt        {}      'noChoice'        ; ...
            'brokeFixation'     sch(-2)  {}       0          {}      'blank'           ; ...
            'noChoice'          sch(-1)  {}       0          {}      'blank'           ; ...
            'choseLeft'         sch( 0)  {}       0          {}      'blank'           ; ...
            'choseRight'        sch( 1)  {}       0          {}      'blank'           ; ...
            'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       tsf        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0          blanks  'done'            ; ...
            'done'              pse      {}       iti        {}      ''                ; ...
            };
                  
         % ---- Set up ensemble activation list. This determines which
         %        states will correspond to automatic, repeated calls to
         %        the given ensemble methods
         %
         % See activateEnsemblesByState for details.
         self.stateMachineActiveList = {{ ...
            self.drawables.stimulusEnsemble, 'draw'; ...
            self.screenEnsemble, 'flip'}, ...
            {'preDots' 'showDotsRT' 'showDotsFX'}};
         
         % --- List of children to add to the stateMachineComposite
         %        (the state list above is added automatically)
         %
         self.stateMachineCompositeChildren = { ...
            self.drawables.stimulusEnsemble, ...
            self.screenEnsemble};
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
                  
         % ---- Get the task object, with optional property/value pairs
         %
         task = topsTreeNodeTaskRTDots(name, varargin{:});
         
         % ---- Set block size
         %
         if ~isempty(trialsPerCoherence)
            task.settings.trialsPerCoherence = trialsPerCoherence;
         end
         
         % ---- Instruction settings, by column:
         %  1. tag (first character of name)
         %  2. Text string #1
         %  3. RTFeedback flag
         %
         SATsettings = { ...
            'S' 'Be as fast as possible.'                 task.settings.referenceRT; ...
            'A' 'Be as accurate as possible.'             nan;...
            'N' 'Be as fast and accurate as possible.'    nan};
         
         dp = task.settings.directionPriors;
         BIASsettings = { ...
            'L' 'Left is more likely.'                    [max(dp) min(dp)]; ...
            'R' 'Right is more likely.'                   [min(dp) max(dp)]; ...
            'N' 'Both directions are equally likely.'     [50 50]};
         
         % For instructions
         if strcmp(name, 'Quest')
            name = 'NN';
         end
         
         % ---- Set strings, priors based on type
         %
         Lsat  = strcmp(name(1), SATsettings(:,1));
         Lbias = strcmp(name(2), BIASsettings(:,1));
         task.drawables.settings.textStrings = ...
            {SATsettings{Lsat, 2}, BIASsettings{Lbias, 2}};
         task.settings.referenceRT     = SATsettings{Lsat, 3};
         task.settings.directionPriors = BIASsettings{Lbias, 3};
      end
   end
end
