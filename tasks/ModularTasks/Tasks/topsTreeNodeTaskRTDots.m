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
      %
      % Set useQuest to a handle to a topsTreeNodeTaskRTDots to use it 
      %     to get coherences
      % Possible values of dotsDuration:
      %     [] (default) ... RT task
      %     [val] ... use given fixed value
      %     [min mean max] ... specify as pick from exponential distribution
      settings = struct( ...
         'minTrialsPerCondition',         10,   ...
         'useQuest',                      [],   ...
         'coherencesFromQuest',           [],   ...
         'directionPriors',               [80 20], ... % For asymmetric priors
         'referenceRT',                   [],   ...
         'fixationRTDim',                 0.4,  ...
         'targetDistance',                8,    ...
         'textStrings',                   '',      ...
         'gazeWindowSize',                6,       ...
         'gazeWindowDuration',            0.15);
           
      % Array of structures of independent variables, used by makeTrials
      indVars = struct( ...
         'name',        {'direction', 'coherence'}, ...
         'values',      {[0 180], [0 3.2 6.4 12.8 25.6 51.2]}, ...
         'priors',      {[], []}, ...
         'minTrials',   {1, []});
      
      % Timing properties .. use three-char tags to reference in statelist
      timing = struct( ...
         'showInstructions_shi',          10.0, ...
         'waitAfterInstructions_wai',     0.5, ...
         'fixationTimeout_fxt',           5.0, ...
         'holdFixation_hfx',              0.5, ...
         'showFeedback_sfb',              1.0, ...
         'interTrialInterval_iti',        1.0, ...
         'showTargetForeperiod_stf',      [0.2 0.5 1.0], ...
         'dotsDuration_ddr',              [],   ... 
         'dotsTimeout_dto',               5.0, ...
         'choiceTimeout_cto',             3.0);
      
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
         'width',                         1.5.*[1 1],       ...
         'height',                        1.5.*[1 1])),      ...
         ...
         ...   % Dots drawable settings
         struct('name',                   'dots', ...
         'type',                          'dotsDrawableDotKinetogram', ...
         'settings',                      struct( ...
         'xCenter',                       0,                ...
         'yCenter',                       0,                ...
         'coherenceSTD',                  10,               ...
         'stencilNumber',                 1,                ...
         'pixelSize',                     6,                ...
         'diameter',                      8,                ...
         'density',                       150,              ...
         'speed',                         3))));

      % Readable settings
      readables = struct( ...
         ...
         ...   % The readable object
         'userInput',                     [],               ...
         ...
         ...   % The gaze windows
         'dotsReadableEye', struct( ...
         'name',              {'holdFixation', 'breakFixation', 'choseLeft', 'choseRight'}, ...
         'isInverted',        {false, true, false, false}, ...
         'windowSize',        {[], [], [], []}, ...
         'windowDur',         {[], [], [], []}, ...
         'ensemble',          {[], [], [], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [1 1], [2 1], [2 2]}), ... % object/item indices
         ...
         ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the userInput type
         'dotsReadableHIDKeyboard', struct( ...
         'name',              {'holdFixation', 'choseLeft', 'choseRight', 'calibrate'}, ...
         'component',         {'KeyboardSpacebar', 'KeyboardF', 'KeyboardJ', 'KeyboardC'}, ...
         'isRelease',         {true, false, false, false}), ...
         ...
         ...   % Gamepad 
         'dotsReadableHIDGamepad', struct( ...
         'name',              {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',         {'Button1', 'Trigger1', 'Trigger2'}, ...
         'isRelease',         {true, false, false}), ...
         ...
         ...   % Ashwin's magic buttons
         'dotsReadableHIDButtons', struct( ...
         'name',              {'holdFixation', 'choseLeft', 'choseRight'}, ...
         'component',         {'KeyboardSpacebar', 'KeyboardLeftShift', 'KeyboardRightShift'}, ...
         'isRelease',         {true, false, false}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy', struct( ...
         'name',              {'holdFixation'}, ...
         'component',         {'automatic'}));
      
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
      end

      %% Start task (overloaded)
      % 
      % Put stuff here that you want to do before each time you run this
      % task
      function startTask(self)

         % ---- Configure each element - separated into different methods for
         % readability
         %
         self.initializeTrialData();
         self.initializeStateMachine();         
         
         % ---- Show task-specific instructions
         %
         self.showText(self.settings.textStrings, [], ...
            self.timing.showInstructions_shi, ...
            self.timing.waitAfterInstructions_wai);       
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
         
         % Conditionally update Quest
         if strcmp(self.name, 'Quest')

            % ---- Check for bad trial
            %
            trial = self.getTrial();
            if isempty(trial) || ~(trial.correct >= 0)
               return
            end
            
            % ---- Update Quest
            %
            % (expects 1=error, 2=correct)
            self.quest = qpUpdate(self.quest, trial.coherence, trial.correct+1);
            
            % Update next guess, bounded between 0 and 100, if there is a next trial
            if self.trialCount < length(self.trialIndices)
               self.trialData(self.trialIndices(self.trialCount+1)).coherence = ...
                  min(100, max(0, qpQuery(self.quest)));
            end
            
            % ---- Set reference coherence to current threshold and set reference RT
            %
            self.settings.coherences  = self.getCoherencesFromQuest(self.settings.coherencesFromQuest);
            self.settings.referenceRT = nanmedian([self.trialData.RT]);
         end
      end
      
      %% Check for choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function nextState = checkForChoice(self, events, eventTag)
         
         % ---- Check for event
         %
         eventName = self.getEventWithTimestamp(self.readables.userInput, ...
            events, eventTag);
         
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
         
         % Compute/save RT
         %  Remember that dotsOn time might be from the remote computer, whereas
         %  sacOn is from the local computer, so we need to account for clock
         %  differences
         if self.isRT
            % RT trial, compute wrt dots on
            trial.RT = (trial.time_ui_choice - trial.time_ui_trialStart) - ...
               (trial.time_screen_dotsOn - trial.time_screen_trialStart);
         else
            % non-RT trial, compute wrt dots off
            trial.RT = (trial.time_ui_choice - trial.time_ui_trialStart) - ...
               (trial.time_screen_dotsOff - trial.time_screen_trialStart);
         end
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);
      end
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % Get current task/trial
         trial = self.getTrial();

         % Set up feedback string
         %  First Correct/error
         if trial.correct == 1
            feedbackString = 'Correct';
         elseif trial.correct == 0
            feedbackString = 'Error';
         else
            feedbackString = 'No choice';            
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
         
         % --- Show trial feedback in GUI/text window
         %
         self.statusStrings{2} = ...
            sprintf('Trial %d/%d, dir=%d, coh=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence, feedbackString, trial.RT);
         self.updateStatus(2); % just update the second one   
         
         % --- Show trial feedback on the screen
         %
         self.showText(feedbackString, 'fdbkOn');
      end
                
      %% Get Coherences from Quest
      %
      % coherencesFromQuest is list of proportion correct values
      %  if given, find associated coherences from QUEST Weibull
      %  Parameters are: threshold, slope, guess, lapse
      %
      function cohs = getCoherencesFromQuest(self, coherencesFromQuest)
         
         if nargin < 2 || isempty(coherencesFromQuest)
            coherencesFromQuest = [];
            cohs = nan;
         else
            cohs = nans(size(coherencesFromQuest));
         end

         % Find values from PMF
         psiParamsIndex = qpListMaxArg(self.quest.posterior);
         psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:);
         
         if ~isempty(psiParamsQuest)
            
            if isempty(coherencesFromQuest)
               
               % Just return threshold
               cohs = psiParamsQuest(1,1);
            else
               
               cax = (0:0.1:100);
               predictedProportions =100*qpPFWeibull(cax', ...
                  [psiParamsQuest(1,1) psiParamsQuest(1,2) 0.5 0]);
               
               cohs = nans(size(coherencesFromQuest));
               for ii = 1:length(coherencesFromQuest)
                  Lp = predictedProportions(:,2)>=coherencesFromQuest(ii);
                  if any(Lp)
                     cohs(ii) = cax(find(Lp,1));
                  end
               end
            end
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
            
            %  Now set the target x,y
            ensemble.setObjectProperty('xCenter', [fpX - td, fpX + td], 2);
            ensemble.setObjectProperty('yCenter', [fpY fpY], 2);
            
            % Utility for updating drawables with standard property format
            self.updateDrawables();
            
            % set updateReadables flag because gaze windows depend on
            % target positions, but not drawables
            self.updateFlags.readables = true;
            self.updateFlags.drawables = false;
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
         ensemble.setObjectProperty('direction', trial.direction, 3);
         
         % ---- Prepare to draw dots stimulus
         %
         ensemble.callObjectMethod(@prepareToDrawInWindow);
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)

         % ---- Set RT/deadline
         %
         self.isRT = isempty(self.timing.dotsDuration_ddr);
      end

      %% Initialize TrialData
      %
      function initializeTrialData(self)
         
         % ---- Get coherences
         %
         if strcmp(self.name, 'Quest')
            
            % This is a Quest task
            %
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
            self.setIndVarByName('coherence', 'values', ...
               min(100, max(0, qpQuery(self.quest))));
            
         elseif ~isempty(self.settings.useQuest)
            
            % Getting coherence from a different Quest Task
            self.setIndVarByName('coherence', 'values', ...
               self.settings.useQuest.getCoherencesFromQuest( ...
               self.settings.coherencesFromQuest));            
         end
                  
         % ---- Call superclass makeTrials method, which uses the indVars
         %           struct
         %
         self.makeTrials();
      end
      
      %% Check for fixation
      function ret = checkForFixation(self)
          
      end
      
      %% Initialize StateMachine
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks  = {@callObjectMethod, self.screenEnsemble, @blank};
         chkuif  = {@getNextEvent, self.readables.userInput, false, {'holdFixation'}};
         chkuib  = {}; % {@getNextEvent, self.readables.userInput, false, {}}; % {'brokeFixation'}
         chkuic  = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choice'};
         showfx  = {@setAndDrawWithTimestamp, self, self.drawables.stimulusEnsemble, ...
            {{'colors', [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, 2:3}}, 'fixOn'};
         showt   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         showfb  = {@showFeedback, self};
         showdRT = {@setAndDrawWithTimestamp, self, self.drawables.stimulusEnsemble, ...
            {{'colors', self.settings.fixationRTDim.*[1 1 1], 1}, {'isVisible', true, 3}}, 'dotsOn'};
         showdFX = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 3, [], 'dotsOn'};
         hided   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], [1 3], 'dotsOff'};
         pdbr    = {@setNextState, self, 'isRT', 'preDots', 'showDotsRT', 'showDotsFX'};
         pse     = {@pause 0.005};

         % drift correction
         hfdc  = {@reset, self.readables.userInput, true};
         
         % Activate/deactivate readable events
         sea   = @setEventsActiveFlag;
         gwfxw = {sea, self.readables.userInput, 'holdFixation'};
         gwfxh = {}; 
         gwts  = {sea, self.readables.userInput, {'choseLeft', 'choseRight'}, 'holdFixation'};
         % gwfxh = {}; % {dce, self.readables.userInput, 'brokeFixation', 'holdFixation'};
         % gwts  = {dce, self.readables.userInput, {'choseLeft', 'choseRight'}, 'brokeFixation'};
         
         % ---- Timing variables, read directly from the timing property struct
         %
         fn = fieldnames(self.timing);
         to = @(x) self.timing.(fn{cell2num(strfind(fn, x))~=0});
         
         % ---- Make the state machine. These will be added into the 
         %        stateMachine (in topsTreeNode)
         %
         states = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          pdbr    'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   to('fxt')  {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   to('hfx')  hfdc    'showTargets'     ; ...
            'showTargets'       showt    chkuib   to('stf')  gwts    'preDots'         ; ...
            'preDots'           {}       {}       0          {}      ''                ; ...
            'showDotsRT'        showdRT  chkuic   to('dto')  hided   'blank'           ; ...
            'showDotsFX'        showdFX  {}       to('ddr')  hided   'waitForChoiceFX' ; ...
            'waitForChoiceFX'   {}       chkuic   to('cto')  {}      'blank'           ; ...
            'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       to('sfb')  blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0          blanks  'done'            ; ...
            'done'              pse      {}       to('iti')  {}      ''                ; ...
            };
                  
         % ---- Set up ensemble activation list. This determines which
         %        states will correspond to automatic, repeated calls to
         %        the given ensemble methods
         %
         % See activateEnsemblesByState for details.
         activeList = {{ ...
            self.drawables.stimulusEnsemble, 'draw'; ...
            self.screenEnsemble, 'flip'}, ...
            {'preDots' 'showDotsRT' 'showDotsFX'}};
         
         % --- List of children to add to the stateMachineComposite
         %        (the state list above is added automatically)
         %
         compositeChildren = { ...
            self.drawables.stimulusEnsemble, ...
            self.screenEnsemble};
         
         % Call utility to set up the state machine
         self.addStateMachine(states, activeList, compositeChildren);
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
         if  nargin >= 2 && ~isempty(minTrialsPerCondition)
            task.settings.minTrialsPerCondition = minTrialsPerCondition;
         end
         
         % ---- Set independent variable properties
         %
         if  nargin >= 3 && ~isempty(indVarList)
            task.setIndVarsByName(indVarList)
         end
         
         % ---- Default trialData
         %
         task.setTrialData( ...
            {'direction', 'coherence', 'randSeedBase', 'choice', 'RT', 'correct'}, ...
            {'screenEnsemble', {'fixOn', 'targsOn', 'dotsOn', 'targsOff', 'fixOff', 'dotsOff', 'fdbkOn'}, ...
            'readableList', {'choice'}});

         % ---- Default gaze windows
         %
         [task.readables.dotsReadableEye.windowSize] = deal(task.settings.gazeWindowSize);
         [task.readables.dotsReadableEye.windowDur]  = deal(task.settings.gazeWindowDuration);

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
         
         % ---- Have it loop forever until instructed to stop 
         %
         task.iterations = inf;
      end
   end
end
