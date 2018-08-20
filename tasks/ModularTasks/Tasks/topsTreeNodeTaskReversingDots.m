classdef topsTreeNodeTaskReversingDots < topsTreeNodeTask
   % @class topsTreeNodeTaskReversingDots
   %
   % Reversing-dots task
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskRTDots.getStandardConfiguration
   % 
   % Otherwise:
   %  1. Create an instance directly:
   %        task = topsTreeNodeTaskReversingDots();
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
      %  NOTE that coherence can be given a different 
      %     topsTreeNodeTask object and get its coherence property
      settings = struct( ...
         'minTrialsPerCondition',         10,      ...
         'useQuest',                      [],      ...
         'coherencesFromQuest',           [60 90], ...
         'directionPriors',               [80 20], ... % For asymmetric priors
         'targetDistance',                8,       ...
         'targetSeparationAngle',         30,      ...
         'textOffset',                    2,       ...
         'textStrings',                   '');
      
      % Array of structures of independent variables, used by makeTrials
      indVars = struct( ...
         'name',        {'direction', 'coherence', 'hazard'}, ...
         'values',      {[0 180], [nan nan]}, ...
         'priors',      {[], [], []}, ...
         'minTrials',   {1, [], 1});
      
      % Timing properties
      timing = struct( ...
         'showInstructions',              10.0, ...
         'waitAfterInstructions',         0.5, ...
         'fixationTimeout',               5.0, ...
         'holdFixation',                  0.5, ...
         'showFeedback',                  1.0, ...
         'InterTrialInterval',            1.0, ...
         'showTargetForeperiod',          [0.2 0.5 1.0], ...
         'dotsDuration',                  [1.0 2.0 5.0]);
      
      % Drawables settings
      drawables = struct( ...
         ...
         ...   % Stimulus ensemble and settings
         'stimulusEnsemble',              [],      ...
         'stimulusEnsembleSettings',      cat(2,   ...
         ...
         ...   % Fixation drawable settings
         struct( ...
         'name',                          'fixation', ...
         'type',                          'dotsDrawableTargets', ...
         'settings',                      struct( ...
         'xCenter',                       0,                ...
         'yCenter',                       0,                ...
         'nSides',                        4,                ...
         'width',                         1.0.*[1.0 0.1],   ...
         'height',                        1.0.*[0.1 1.0],   ...
         'colors',                        [1 1 1])),        ...
         ...
         ...   % Targets drawable settings
         struct( ...
         'name',                          'targets', ...
         'type',                          'dotsDrawableTargets', ...
         'settings',                      struct( ...
         'nSides',                        100,              ...
         'width',                         1.5.*[1 1 1 1],       ...
         'height',                        1.5.*[1 1 1 1])),      ...
         ...
         ...   % Dots drawable settings
         struct( ...
         'name',                          'dots', ...
         'type',                          'dotsDrawableDotKinetogram', ...
         'settings',                      struct( ...
         'xCenter',                       0,                ...
         'yCenter',                       0,                ...
         'coherenceSTD',                  10,               ...
         'stencilNumber',                 1,                ...
         'pixelSize',                     6,                ...
         'diameter',                      8,                ...
         'density',                       150,              ...
         'speed',                         3))), ...
         ...
         ...   % Text ensemble (no settings, use defaults)
         'textEnsemble',                  []);

      % Readable settings
      readables = struct( ...
         ...
         ...   % The readable object
         'userInput',                     [],               ...
         ...
         ...   % The gaze windows
         'dotsReadableEye', struct( ...
         'name',              {'holdFixation', 'breakFixation', 'choseLL', 'choseLR', 'choseHL', 'choseHR'}, ...
         'isInverted',        {false, true, false, false, false, false}, ...
         'windowSize',        {8, 8, 8, 8, 8, 8}, ...
         'windowDur',         {0.15, 0.15, 0.15, 0.15, 0.15, 0.15}, ...
         'ensemble',          {[], [], [], [], [], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [1 1], [2 1], [2 2], [2 3], [2 4]}), ... % object/item indices
         ...
         ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the userInput type
         'dotsReadableHIDKeyboard', struct( ...
         'name',              {'holdFixation', 'choseLL', 'choseLR', 'choseHL', 'choseHR', 'calibrate'}, ...
         'component',         {'KeyboardSpacebar', 'KeyboardV', 'KeyboardN', 'KeyboardF', 'KeyboardJ', 'KeyboardC'}));      
   end
   
   properties (SetAccess = protected)
      
      % Array of planned dot reversal times for this trial
      plannedDotReversalTimes;
      
      % Time of next dot reversal
      nextDotReversalTime;
      
      % Array of actual dot reversal times (saved to data log after each
      % trial)
      actualDotReversalTimes;      
      
      % Keep for speed
      thisDirection;
      nextDirection;    
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
            self.settings.textStrings, ...
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
      
      %% Check for choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function nextState = checkForChoice(self)
         
         % ---- Check for event
         %
         eventName = self.getEventWithTimestamp(self.readables.userInput, ...
            {'choseLeft' 'choseRight'}, 'choice');
         
         % Nothing... keep checking
         if isempty(eventName)
            nextState = [];
            return
         end
         
         % ---- Good choice!
         %
         % Override completedTrial flag
         self.completedTrial = true;
         
         % Jump to next state when done
         nextState = 'blank';
         
         % Get current task/trial
         trial = self.getTrial();
         
         % Save the choice
         trial.choice = double(strcmp(eventName, 'choseRight'));
         
         % Mark as correct/error
         trial.correct = double( ...
            (trial.choice==0 && trial.direction==180) || ...
            (trial.choice==1 && trial.direction==0));
         
         % Compute/save RT wrt dots off
         %  Remember that dotsOn time might be from the remote computer, whereas
         %  sacOn is from the local computer, so we need to account for clock
         %  differences
         trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
            (trial.time_dotsOff - trial.time_screen_trialStart);
         
         % Set up feedback string
         %  First Correct/error
         if trial.correct == 1
            feedbackString = 'Correct';
         else
            feedbackString = 'Error';
         end

         % Set the feedback string
         self.drawables.textEnsemble.setObjectProperty('string', feedbackString, 1);

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
      end      
      
      %% Check for flip
      %
      %
      function checkForFlip(self)
              
         % Nothing to do
         if isempty(self.plannedDotReversalTimes)
            return
         end
         
         % Get the trial for timing info
         trial = self.getTrial();

         % Set up first reversal time wrt dots onset
         if isempty(self.nextDotReversalTime)            
          
            % Set it
            self.nextDotReversalTime = trial.time_local_trialStart + ...
               (trial.time_dotsOn - trial.time_screen_trialStart) + ...
               self.plannedDotReversalTimes(1);
            
            % remove it from the queue
            self.plannedDotReversalTimes(1) = [];
         end
            
         % Check for reversal time
         if mglGetSecs >= self.nextDotReversalTime
            
            % Set the values
            old = self.thisDirection;
            self.thisDirection = self.nextDirection;
            self.nextDirection = old;
            
            % Set the direction
            self.drawables.stimulusEnsemble.setObjectProperty( ...
               'direction', self.thisDirection, 3);

            % Explicitly flip here so we can get the timestamp
            ret = self.drawables.stimulusEnsemble.callObjectMethod( ...
               @dotsDrawable.drawFrame, {}, [], true);

            % Set next flip time
            if isempty(self.plannedDotReversalTimes)
               
               % No more flips
               self.nextDotReversalTime = inf;
            else
               
               % Set it
               self.nextDotReversalTime = trial.time_local_trialStart + ...
                  (ret.onsetTime - trial.time_screen_trialStart) + ...
                  self.plannedDotReversalTimes(1);
               
               % remove it from the queue
               self.plannedDotReversalTimes(1) = [];
            end
            
            % Save the flip time
            self.actualDotReversalTimes = cat(2, self.actualDotReversalTimes, ...
               ret.onsetTime);
         end
      end
   end
   
   methods (Access = private)
           
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % ---- Get the current trial and the stimulus ensemble
         % 
         trial    = self.getTrial();
         ensemble = self.drawables.stimulusEnsemble;
         
         % ---- Possibly update all stimulusEnsemble objects
         %
         if self.updateFlags.drawables
            
            % Target locations
            %
            %  Determined relative to fp location
            fpX = ensemble.getObjectProperty('xCenter', 1);
            fpY = ensemble.getObjectProperty('yCenter', 1);
            td  = self.settings.targetDistance;
            tx  = td*cosd(self.settings.targetSeparationAngle);
            ty  = td*sind(self.settings.targetSeparationAngle);
            
            %  Now set the target x,y. In order: 
            %     'choseLL', 'choseLR', 'choseHL', 'choseHR'
            ensemble.setObjectProperty('xCenter', [fpX-tx fpX+tx fpX-tx fpX+tx], 2);
            ensemble.setObjectProperty('yCenter', [fpY-ty fpX-ty fpX+ty fpX+ty], 2);
            
            % Utility for updating drawables with standard property format
            self.updateDrawables();
            
            % set updateReadables flag because gaze windows depend on
            % target positions, but not drawables
            self.updateFlags.readables = true;
            self.updateFlags.drawables = false;
         end
         
         % ---- Prepare the dot reversals
         %
         % Set the dot duration
         duration = self.sampleTime(self.settings.dotsDuration);
         editStateByName(self.stateMachine, 'showDots', 'timeout', duration);

         % Get the reversal times
         revs = exprnd(1/trial.hazard, 1000, 1);
         Lrev = cumsum(revs)<=duration;
         self.plannedDotReversalTimes = revs(Lrev);
         self.nextDotReversalTime = []; % this gets set in checkForFlip
         
         % Possibly re-code the direction         
         if rem(sum(Lrev),2)==0
            self.thisDirection = trial.direction;
            self.nextDirection = setdiff(self.indVars(1).values, trial.direction);
         else
            self.thisDirection = setdiff(self.indVars(1).values, trial.direction);
            self.nextDirection = trial.direction;
         end
         
         % ---- Set a new seed base for the dots random-number process
         %
         trial.randSeedBase = randi(99999);
         self.setTrial(trial);
        
         % ---- Save the randBase, coherence, and direction to the dots object
         %        in the stimulus ensemble
         %
         ensemble.setObjectProperty('randBase',  trial.randSeedBase, 3);
         ensemble.setObjectProperty('coherence', trial.coherence, 3);
         ensemble.setObjectProperty('direction', self.thisDirection, 3);
         
         % ---- Prepare to draw dots stimulus
         %
         ensemble.callObjectMethod(@prepareToDrawInWindow);
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)
      end    
      
      %% Initialize TrialData
      %
      function initializeTrialData(self)
         
         % ---- Possibly set coherence from Quest
         %
         if ~isempty(self.settings.useQuest)
            
            % Getting coherence from a different Quest Task
            self.setIndVarByName('coherence', 'values', ...
               self.settings.useQuest.getCoherencesFromQuest( ...
               self.settings.coherencesFromQuest));
         end
         
         % ---- Set up the trialData struct
         %
         self.trialData = struct( ...
            'taskID',            nan, ...
            'trialIndex',        nan, ...
            'direction',         nan, ...
            'coherence',         nan, ...
            'hazard',            nan, ...
            'randSeedBase',      nan, ...
            'choice',            nan, ...
            'RT',                nan, ...
            'correct',           nan, ...
            'time_fixOn',        nan, ...
            'time_targsOn',      nan, ...
            'time_dotsOn',       nan, ...
            'time_targsOff',     nan, ...
            'time_fixOff',       nan, ...
            'time_choice',       nan, ...
            'time_dotsOff',      nan, ...
            'time_fdbkOn',       nan);
         
         % ---- Call superclass makeTrials method
         %
         self.makeTrials();         
      end
      
      %% Initialize StateMachine
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks  = {@callObjectMethod, self.screenEnsemble, @blank};
         chkuif  = {@getNextEvent, self.readables.userInput, false, {'holdFixation'}};
         chkuib  = {}; % {@getNextEvent, self.readables.userInput, false, {}}; % {'brokeFixation'}
         chkuic  = {@checkForChoice, self};
         chkflp  = {@checkForFlip, self};
         showfx  = {@setAndDrawWithTimestamp, self, self.drawables.stimulusEnsemble, ...
            {{'colors', [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, 2:3}}, 'fixOn'};
         showt   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         showfb  = {@drawWithTimestamp, self, self.drawables.textEnsemble, 1, [], 'fdbkOn'};
         showd   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 3, [], 'dotsOn'};
         hided   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], [1 3], 'dotsOff'};
         pse     = {@pause 0.005};

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
         tsf = self.timing.showFeedback;
         iti = self.timing.InterTrialInterval;         
         
         % ---- Make the state machine. These will be added into the 
         %        stateMachine (in topsTreeNode)
         %
         self.stateMachineStates = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   tfh        hfdc    'showTargets'     ; ...
            'showTargets'       showt    chkuib   txp        gwts    'preDots'         ; ...
            'preDots'           {}       {}       0          {}      ''                ; ...
            'showDots'          showd    chkflp   0          hided   'waitForChoice'   ; ...
            'waitForChoice'     {}       chkuic   dtt        {}      'blank'           ; ...
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
      function task = getStandardConfiguration(name, minTrialsPerCondition, indVarList, varargin)
                  
         % ---- Get the task object, with optional property/value pairs
         %
         task = topsTreeNodeTaskRTDots(name, varargin{:});
         
         % ---- Set min trial count
         %
         if ~isempty(minTrialsPerCondition)
            task.settings.minTrialsPerCondition = minTrialsPerCondition;
         end
         
         % ---- Set independent variable properties
         %
         if ~isempty(indVarList)
            task.setIndVarsByName(indVarList)
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
         task.settings.textStrings = {SATsettings{Lsat, 2}, BIASsettings{Lbias, 2}};
         task.settings.referenceRT = SATsettings{Lsat, 3};
         task.setIndVarByName('direction', 'priors', BIASsettings{Lbias, 3});
      end
   end
end
