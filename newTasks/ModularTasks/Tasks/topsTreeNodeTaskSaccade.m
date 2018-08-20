classdef topsTreeNodeTaskSaccade < topsTreeNodeTask
   % @class topsTreeNodeTaskSaccade
   %
   % Visually and Memory guided saccade tasks
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskSaccade.getStandardConfiguration
   % 
   % Otherwise:
   %  1. Create an instance directly:
   %        task = topsTreeNodeTaskSaccade();
   %
   %  2. Set properties. These are required:
   %        task.drawables.screenEnsemble
   %        task.readables.userInput
   %     Others can use defaults
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 5/28/18 created by jig
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties.
      settings = struct( ...
         'minTrialsPerCondition',      10,  ...
         'targetDistance',             8,   ...
         'textOffset',                 2,   ...
         'textStrings',                '');
      
      % Array of structures of independent variables, used by makeTrials
      indVars = struct( ...
         'name',                       {'direction'},       ...
         'values',                     {0:45:315},          ...
         'priors',                     {[]},                ...
         'minTrials',                  {[]});

      % Task timing, all in sec
      timing = struct( ...
         'showInstructions',           10.0, ...
         'waitAfterInstructions',      0.5,  ...
         'fixationTimeout',            5.0,  ...
         'holdFixation',               0.5,  ...
         'showFeedback',               1.0,  ...
         'InterTrialInterval',         1.0,  ...
         'VGSTargetDuration',          1.0,  ...
         'MGSTargetDuration',          0.25, ...
         'MGSDelayDuration',           0.75, ...
         'saccadeTimeout',             5.0);
      
      % Drawables settings
      drawables = struct( ...
         ...
         ...   % Ensembles
         'stimulusEnsemble',           [],	...
         'stimulusEnsembleSettings',   cat(2,   ...
         ...
         ...   % Fixation drawable settings
         struct( ...
         'name',                       'fixation', ...
         'type',                       'dotsDrawableTargets', ...
         'settings',                   struct( ...
         'xCenter',                    0,                ...
         'yCenter',                    0,                ...
         'nSides',                     4,                ...
         'width',                      1.0.*[1.0 0.1],   ...
         'height',                     1.0.*[0.1 1.0],   ...
         'colors',                     [1 1 1])),        ...
         ...
         ...   % Targets drawable settings
         struct(  ...
         'name',                       'target', ...
         'type',                       'dotsDrawableTargets', ...
         'settings',                   struct(   ...
         'nSides',                     100,      ...
         'width',                      1.5,      ...
         'height',                     1.5))), ...
         ...
         ...   % Text ensemble (no settings, use defaults)
         'textEnsemble',               []);   
      
      % Readable settings
      readables = struct( ...
         ...
         ...   % The readable object
         'userInput',                  [],      ...
         ...
         ...   % Gaze windows
         'dotsReadableEye', struct( ...
         'name',              {'holdFixation', 'breakFixation', 'choseTarget'}, ...
         'windowSize',        {8, 8, 8}, ...
         'windowDur',         {0.15, 0.15, 0.15}, ...
         'ensemble',          {[], [], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [1 1], [2 1]}), ... % object/item indices
         ...
         ...   % Keyboard events 
         'dotsReadableHIDKeyboard', struct( ...
         'name',        {'holdFixation', 'choseTarget', 'calibrate'}, ...
         'component',   {'KeyboardSpacebar', 'KeyboardT', 'KeyboardC'}));
   end
   
   properties (SetAccess = private)
      
      % keep track of target x,y
      targetXY = [nan nan];      
   end
   
   methods
      
      %% Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTaskSaccade(varargin)
         
         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(varargin{:});
      end
   
      %% Start task method
      function startTask(self)
         
         % ---- Configure each element - separated for readability
         % 
         self.initializeDrawables();
         self.initializeReadables();
         self.makeTrials();
         self.initializeStateMachine();
         
         % ---- Show task-specific instructions
         %
         drawTextEnsemble(self.drawables.textEnsemble, ...
            self.settings.textStrings, ...
            self.timing.showInstructions, ...
            self.timing.waitAfterInstructions);         
      end
      
      %% Finish task method
      function finishTask(self)         
      end
      
      %% Start trial method
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
            sprintf('%s (task %d/%d): mean RT=%.2f', ...
            self.name, self.taskID, length(self.caller.children), ...
            nanmean([self.trialData.RT])), ...
            ... % Trial info
            sprintf('Trial %d/%d, dir=%d', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction)};
         self.updateStatus(); % just update the second one
      end
      
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
      end
      
       %% Set Choice method
      %
      % Save choice/RT information and set up feedback
      function setSaccadeChoice(self, value)
         
         % ---- Get current task/trial and save the choice/correct flag
         %
         trial = self.getTrial();
         trial.choice = value;
         trial.correct = value;
         
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
            % Set feedback
            feedbackString = 'Correct';

            % Override completedTrial flag
            self.completedTrial = true;

            % Compute/save RT
            %  Remember that time_choice time is from the UI, whereas
            %    fixOff is from the remote computer, so we need to
            %    account for clock differences
            trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
               (trial.time_fixOff - trial.time_screen_trialStart);
         end
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);
         
         % ---- Set the feedback string
         %
         self.drawables.textEnsemble.setObjectProperty('string', feedbackString, 1);
         
         % --- Show trial feedback
         %
         self.statusStrings{2} = ...
            sprintf('Trial %d/%d, dir=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, feedbackString, trial.RT);
         self.updateStatus(2); % just update the second one
      end
   end
   
   methods (Access = private)
      
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % ---- Get the current trial
         % 
         trial = self.getTrial();
         
         % ---- Always set target location
         %
         % Get x,y location of center of target
         targetDistance = self.settings.targetDistance;
         targetSettings = self.drawables.stimulusEnsembleSettings(1).settings;
         
         newX = targetSettings.xCenter + targetDistance * cosd(trial.direction);
         newY = targetSettings.yCenter + targetDistance * sind(trial.direction);
         self.drawables.stimulusEnsemble.setObjectProperty('xCenter', newX, 2);
         self.drawables.stimulusEnsemble.setObjectProperty('yCenter', newY, 2);
         
         % Target changed, so set flag to update readables (gaze window)
         if newX~=self.targetXY(1) || newY~=self.targetXY(2)
            self.updateFlags.readables = true;
            self.targetXY = [newX newY];
         end
         
         % ---- Conditionally update all stimulusEnsemble objects
         %
         if self.updateFlags.drawables
            
            % All other stimulus ensemble properties
            self.updateDrawables();

            % Unset the flag
            self.updateFlags.drawables = false;
         end
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)
         
         % ---- Update stateMachine to jump to VGS-/MGS- specific states
         %
         editStateByName(self.stateMachine, 'holdFixation', 'next', ...
            [self.name 'showTarget']);
      end
      
      %% configureStateMachine method
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         dnow   = {@drawnow};
         blanks = {@callObjectMethod, self.screenEnsemble, @blank};
         chkuif = {@getNextEvent, self.readables.userInput, false, {'holdFixation'}};
         chkuib = {}; % {@getNextEvent, self.readables.userInput, false, {}}; % {'brokeFixation'}
         chkuic = {@getEventWithTimestamp, self, self.readables.userInput, {'choseTarget'}, 'choice'};
         showfx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 1, 2, 'fixOn'};
         showt  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         hidet  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], 2, 'targsOff'};
         hidefx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], 1, 'fixOff'};
         showfb = {@drawWithTimestamp, self, self.drawables.textEnsemble, 1, [], 'fdbkOn'};
         sch    = @(x)cat(2, {@setSaccadeChoice, self}, x);
         
         % drift correction
         hfdc  = {@reset, self.readables.userInput, true};
         
         % Activate/deactivate readable events
         dce   = @setEventsActiveFlag;
         gwfxw = {dce, self.readables.userInput, 'holdFixation'};
         gwfxh = {}; 
         gwt   = {dce, self.readables.userInput, 'choseTarget', 'holdFixation'};
         % gwfxh = {}; % {dce, self.readables.userInput, 'brokeFixation', 'holdFixation'};
         % gwts  = {dce, self.readables.userInput, 'choseTarget', 'brokeFixation'};

         % ---- Timing variables
         %
         tft = self.timing.fixationTimeout;
         tfh = self.timing.holdFixation;
         vtd = self.timing.VGSTargetDuration;
         mtd = self.timing.MGSTargetDuration;
         mdd = self.timing.MGSDelayDuration;
         sto = self.timing.saccadeTimeout;
         tsf = self.timing.showFeedback;
         iti = self.timing.InterTrialInterval;
         
         % ---- Make the state machine
         %
         % Note that the startTrial routine sets the target location and the 'next'
         % state after holdFixation, based on VGS vs MGS task
         self.stateMachineStates = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   tfh        hfdc    'showTarget'      ; ... % Branch here
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
            'done'              dnow     {}       iti        {}      ''                ; ...
            };
      end
   end
   
   methods (Static)
      
      %% ---- Utility for defining standard configurations
      %
      % name is string:
      %  'VGS' for visually guided saccade
      %  'MGS' for memory guided saccade
      %
      function task = getStandardConfiguration(name, minTrialsPerCondition, indVarList, varargin)
         
         % ---- Get the task object, with optional property/value pairs
         task = topsTreeNodeTaskSaccade(name, varargin{:});
         
         % ---- Use given trials per direction
         %
         if ~isempty(minTrialsPerCondition)
            task.settings.minTrialsPerCondition = minTrialsPerCondition;
         end
         
         % ---- Set independent variable properties
         %
         if ~isempty(indVarList)
            task.setIndVarsByName(indVarList)
         end
         
         % ---- Instruction strings
         %
         switch name
            case 'VGS'
               task.settings.textStrings = { ...
                  'Look at the red cross. When it disappears,', ...
                  'look at the visual target.'};
            otherwise
               task.settings.textStrings = { ...
                  'Look at the red cross. When it disappears,', ...
                  'look at the remebered location of the visual target.'};
         end
      end
   end
end