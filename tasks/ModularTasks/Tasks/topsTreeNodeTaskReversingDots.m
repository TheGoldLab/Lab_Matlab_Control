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
         'textStrings',                   '',      ...
         'gazeWindowSize',                5,       ...
         'gazeWindowDuration',            0.15);
      
      % Array of structures of independent variables, used by makeTrials
      indVars = struct( ...
         'name',        {'direction', 'coherence', 'hazard'}, ...
         'values',      {[0 180], [100], [1]}, ...
         'priors',      {[], [], []}, ...
         'minTrials',   {1, [], 1});
      
      % Timing properties
      timing = struct( ...
         'showInstructions_shi',          10.0, ...
         'waitAfterInstructions_wai',     0.5, ...
         'fixationTimeout_fxt',           5.0, ...
         'holdFixation_hfx',              0.5, ...
         'showFeedback_sfb',              1.0, ...
         'interTrialInterval_iti',        1.0, ...
         'showTargetForeperiod_stf',      [0.2 0.5 1.0], ...
         'dotsDuration_ddr',              (100:100:500)/1000,   ...
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
         'coherenceSTD',                  20,               ...
         'stencilNumber',                 1,                ...
         'pixelSize',                     2,                ...
         'diameter',                      10,                ...
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
         'name',              {'holdFixation', 'breakFixation', 'choseLL', 'choseLR', 'choseHL', 'choseHR'}, ...
         'isInverted',        {false, true, false, false, false, false}, ...
         'windowSize',        {[], [], [], [], [], []}, ...
         'windowDur',         {[], [], [], [], [], []}, ...
         'ensemble',          {[], [], [], [], [], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [1 1], [2 1], [2 2], [2 3], [2 4]}), ... % object/item indices
         ...
         ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the userInput type
         'dotsReadableHIDKeyboard', struct( ...
         'name',              {'holdFixation', 'choseLL', 'choseLR', 'choseHL', 'choseHR', 'calibrate'}, ...
         'component',         {'KeyboardSpacebar', 'KeyboardV', 'KeyboardN', 'KeyboardF', 'KeyboardJ', 'KeyboardC'}));      
   end
   
   properties (SetAccess = protected)
      
      % Time of next dot reversal
      nextDotReversalTime;
      
      % Array of actual dot reversal times (saved to data log after each trial)
      dotReversalTimes;      
      
      % Keep for speed
      directions;
      
      % For feedback
      feedbackString;
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
            sprintf('Trial %d/%d, dir=%d, coh=%d, haz=%d', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence, trial.hazard)};
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
      function nextState = checkForChoice(self, events, eventTag)
         
         % ---- Check for event
         %
         eventName = self.getEventWithTimestamp(self.readables.userInput, ...
            events, eventTag);
         
         % Nothing... keep checking
         if isempty(eventName)
            nextState = '';
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
         
         % Save the direction/choice
         trial.direction = self.directions(1);
         trial.choice = find(strcmp(eventName, {self.readables.dotsReadableEye(3:6).name}));
         
         % Mark as correct/error
         %  0   = both wrong
         %  0.1 = correct hazard, wrong direction
         %  0.2 = wrong hazard, correct direction
         %  1 = both correct
         dirs    = self.indVars(strcmp('direction', {self.indVars.name})).values;
         hazards = self.indVars(strcmp('hazard', {self.indVars.name})).values;
         
         % Find direction choice
         if trial.choice==1 || trial.choice==3
            choiceDir = dirs(cosd(dirs)<0); % LEFT
         else
            choiceDir = dirs(cosd(dirs)>0); % RIGHT
         end
         
         % Find hazard choice
         if trial.choice <= 2
            choiceHaz = min(hazards);
         else
            choiceHaz = max(hazards);
         end
         
         if choiceDir == trial.direction && choiceHaz == trial.hazard
            trial.correct = 1;
            self.feedbackString = 'Both correct';
         elseif choiceDir == trial.direction && choiceHaz ~= trial.hazard
            trial.correct = 0.2;
            self.feedbackString = 'Direction correct';
         elseif choiceDir ~= trial.direction && choiceHaz == trial.hazard
            trial.correct = 0.1;
            self.feedbackString = 'Hazard correct';
         else
            trial.correct = 0;
            self.feedbackString = 'Error';
         end
                 
         % Compute/save RT wrt dots off
         %  Remember that dotsOn time might be from the remote computer, whereas
         %  sacOn is from the local computer, so we need to account for clock
         %  differences
         trial.RT = (trial.time_ui_choice - trial.time_ui_trialStart) - ...
            (trial.time_screen_dotsOff - trial.time_screen_trialStart);
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);                  
      end   
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % Get current task/trial
         trial = self.getTrial();

         % --- Show trial feedback in GUI/text window
         %
         self.statusStrings{2} = ...
            sprintf('Trial %d/%d, dir=%d, coh=%d, haz=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, trial.coherence, trial.hazard, self.feedbackString, trial.RT);
         self.updateStatus(2); % just update the second one   
         
         % --- Show trial feedback on the screen
         %
         self.showText(self.feedbackString, 'fdbkOn');
      end
      
      %% Check for flip
      %
      %
      function next = checkForFlip(self)
         
         % For now, never return anything
         next = '';
         
         % Get the trial for timing info
         trial = self.getTrial();

         % Set up first reversal time wrt dots onset
         if isempty(self.nextDotReversalTime)            
          
            % Set it
            self.nextDotReversalTime = trial.time_local_trialStart + ...
               (trial.time_screen_dotsOn - trial.time_screen_trialStart) + ...
               .2;
            
            %             disp(sprintf('Hazard is %.2f, next flip in %.2f sec', ...
            %                trial.hazard, self.nextDotReversalTime - mglGetSecs))
         end
            
         % Check for reversal time
         if mglGetSecs >= self.nextDotReversalTime
            
            % Set the values
            self.directions = fliplr(self.directions);
            
            % Set the direction
            self.drawables.stimulusEnsemble.setObjectProperty( ...
               'direction', self.directions(1), 3);

            % Explicitly flip here so we can get the timestamp
            ret = self.drawables.stimulusEnsemble.callObjectMethod( ...
               @dotsDrawable.drawFrame, {}, [], true);

            % Set next reversal time
            self.nextDotReversalTime = Inf;

%             disp(sprintf('FLIPPED from %d to %d, next flip in %.2f sec', ...
%                self.directions(2), self.directions(1), ...
%                self.nextDotReversalTime - mglGetSecs))

            % Save the flip time
            self.dotReversalTimes(end+1) = ret.onsetTime;
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
         
         % ---- Set dots parameters for this trial
         %
         % Set current/alternative direction, so it's easy to flip
         self.directions = self.indVars(strcmp('direction', {self.indVars.name})).values;
         if self.directions(1) ~= trial.direction;         
            self.directions = fliplr(self.directions);
         end
         self.nextDotReversalTime = [];
         self.feedbackString = 'No Choice';
         
         % Pick a new seed base (for now), and save it
         trial.randSeedBase = randi(99999);
         self.setTrial(trial);
         
         % Set the ensemble properties and prepare to draw
         ensemble.setObjectProperty('randBase',  trial.randSeedBase, 3);
         ensemble.setObjectProperty('coherence', trial.coherence, 3);
         ensemble.setObjectProperty('direction', trial.direction, 3);
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
         chkuic  = {@checkForChoice, self, {self.readables.dotsReadableEye(3:6).name}, 'choice'};
         chkflp  = {@checkForFlip, self};
         showfx  = {@setAndDrawWithTimestamp, self, self.drawables.stimulusEnsemble, ...
            {{'colors', [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, 2:3}}, 'fixOn'};
         showt   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         showfb  = {@showFeedback, self};
         showd   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 3, [], 'dotsOn'};
         hided   = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], [1 3], 'dotsOff'};
         pse     = {@pause 0.005};

         % drift correction
         hfdc  = {@reset, self.readables.userInput, true};
         
         % Activate/deactivate readable events
         dce   = @setEventsActiveFlag;
         gwfxw = {dce, self.readables.userInput, 'holdFixation'};
         gwfxh = {}; 
         gwts  = {dce, self.readables.userInput, {self.readables.dotsReadableEye(3:6).name}, 'holdFixation'};
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
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   to('fxt')  {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   to('hfx')  hfdc    'showTargets'     ; ...
            'showTargets'       showt    chkuib   to('stf')  gwts    'preDots'         ; ...
            'preDots'           {}       {}       0          {}      'showDots'        ; ...
            'showDots'          showd    chkflp   to('ddr')  hided   'waitForChoice'   ; ...
            'waitForChoice'     {}       chkuic   to('cto')  {}      'blank'           ; ...
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
            {'preDots' 'showDots'}};
         
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
         task = topsTreeNodeTaskReversingDots(name, varargin{:});
         
         % ---- Set min trial count
         %
         if nargin >= 2 && ~isempty(minTrialsPerCondition)
            task.settings.minTrialsPerCondition = minTrialsPerCondition;
         end
         
         % ---- Set independent variable properties
         %
         if nargin >= 3 && ~isempty(indVarList)
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

         % ---- Set the instruction strings
         %
         task.settings.textStrings = { ...
            'The flickering dots will switch directions back-and-forth', ...
            'Please indicate the final direction it was moving when extinguished'};
         
         % ---- Have it loop forever until instructed to stop
         %
         task.iterations = inf;
      end
   end
end
