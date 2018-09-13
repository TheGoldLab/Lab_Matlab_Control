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
         'textStrings',                '',  ...
         'gazeWindowSize',             6,   ...
         'gazeWindowDuration',         0.15);
      
      % Array of structures of independent variables, used by makeTrials
      indVars = struct( ...
         'name',                       {'direction'},       ...
         'values',                     {0:45:315},          ...
         'priors',                     {[]},                ...
         'minTrials',                  {[]});

      % Task timing, all in sec
      timing = struct( ...
         'showInstructions_shi',       10.0, ...
         'waitAfterInstructions_wai',	0.5, ...
         'fixationTimeout_fxt',      	5.0, ...
         'holdFixation_hfx',        	0.5, ...
         'showFeedback_sfb',           1.0, ...
         'interTrialInterval_iti',  	1.0, ...
         'VGSTargetDuration_vgt',      1.0,  ...
         'MGSTargetDuration_mgt',    	0.25, ...
         'MGSDelayDuration_mgm',       0.75, ...
         'saccadeTimeout_sto',         5.0);
      
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
         'height',                     1.5))));   
      
      % Readable settings
      readables = struct( ...
         ...
         ...   % The readable object
         'userInput',                  [],      ...
         ...
         ...   % Gaze windows
         'dotsReadableEye', struct( ...
         'name',              {'holdFixation', 'breakFixation', 'choseTarget'}, ...
         'windowSize',        {[], [], []}, ...
         'windowDur',         {[], [], []}, ...
         'ensemble',          {[], [], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [1 1], [2 1]}), ... % object/item indices
         ...
         ...   % Keyboard events 
         'dotsReadableHIDKeyboard', struct( ...
         'name',        {'holdFixation', 'choseTarget', 'calibrate'}, ...
         'component',   {'KeyboardSpacebar', 'KeyboardT', 'KeyboardC'}, ...
         'isRelease',   {true, false, false}), ...
         ...
         ...   % Gamepad 
         'dotsReadableHIDGamepad', struct( ...
         'name',        {'holdFixation', 'choseTarget'}, ...
         'component',   {'Button1', 'Trigger1'}, ...
         'isRelease',   {true, false}), ...
         ...
         ...    % Ashwin's magic buttons
         'dotsReadableHIDButtons', struct( ...
         'name',        {'holdFixation', 'choseTarget'}, ...
         'component',   {'KeyboardLeftShift', 'KeyboardRightShift'}, ...
         'isRelease',   {true, false}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy', struct( ...
         'name',              {'holdFixation', 'choseTarget'}, ...
         'component',         {'auto_1', 'auto_2'}));
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
         self.makeTrials(); % uses the indVars struct
         self.initializeStateMachine();
         
         % ---- Show task-specific instructions
         %
         self.showText(self.settings.textStrings, [], ...
            self.timing.showInstructions_shi, ...
            self.timing.waitAfterInstructions_wai);       
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
          
          % Mark as correct
          trial.correct = 1;
          
          % Compute/save RT
          %  Remember that time_choice time is from the UI, whereas
          %    fixOff is from the remote computer, so we need to
          %    account for clock differences
          trial.RT = (trial.time_ui_choice - trial.time_ui_trialStart) - ...
             (trial.time_screen_fixOff - trial.time_screen_trialStart);
          
          % ---- Re-save the trial
          %
          self.setTrial(trial);
       end
      
       %% Show feedback
       %
       function showFeedback(self)
          
          % ---- Show trial feedback
          %
          trial = self.getTrial();
          
          % ---- Show the feedback string
          %
          if trial.correct == 1
             feedbackString = 'Correct';
          else
             feedbackString = 'No choice';
          end
          
          % --- Show trial feedback
          %
          self.statusStrings{2} = ...
             sprintf('Trial %d/%d, dir=%d: %s, RT=%.2f', ...
             self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, feedbackString, trial.RT);
         self.updateStatus(2); % just update the second one

         % --- Show trial feedback on the screen
         %
         self.showText(feedbackString, 'fdbkOn');
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
         chkuic = {@checkForChoice, self, {'choseTarget'}, 'choice'};
         showfx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 1, 2, 'fixOn'};
         showt  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         hidet  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], 2, 'targsOff'};
         hidefx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], 1, 'fixOff'};
         showfb = {@showFeedback, self};
         
         % drift correction
         hfdc  = {@reset, self.readables.userInput, true};
         
         % Activate/deactivate readable events
         sea   = @setEventsActiveFlag;
         gwfxw = {sea, self.readables.userInput, 'holdFixation'};
         gwfxh = {}; 
         gwt   = {sea, self.readables.userInput, 'choseTarget', 'holdFixation'};
         % gwfxh = {}; % {dce, self.readables.userInput, 'brokeFixation', 'holdFixation'};
         % gwts  = {dce, self.readables.userInput, 'choseTarget', 'brokeFixation'};

         % ---- Timing variables, read directly from the timing property struct
         %
         fn = fieldnames(self.timing);
         to = @(x) self.timing.(fn{cell2num(strfind(fn, x))~=0});

         % ---- Make the state machine
         %
         % Note that the startTrial routine sets the target location and the 'next'
         % state after holdFixation, based on VGS vs MGS task
         states = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   to('fxt')  {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   to('hfx')  hfdc    'showTarget'      ; ... % Branch here
            'VGSshowTarget'     showt    chkuib   to('vgt')  gwt     'hideFix'         ; ... % VGS
            'MGSshowTarget'     showt    chkuib   to('mgt')  {}      'MGSdelay'        ; ... % MGS
            'MGSdelay'          hidet    chkuib   to('mgm')  gwt     'hideFix'         ; ...
            'hideFix'           hidefx   chkuic   to('sto')  {}      'blank'           ; ...
            'blank'             {}       {}       0.2        blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       to('sfb')  blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0          blanks  'done'            ; ...
            'done'              dnow     {}       to('iti')  {}      ''                ; ...
            };
         
         % make the state machine
         self.addStateMachine(states);
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
            {'direction', 'RT', 'correct'}, ...
            {'screenEnsemble', {'fixOn', 'targsOn', 'targsOff', 'fixOff', 'fdbkOn'}, ...
            'readableList', {'choice'}});
         
         % ---- Default gaze windows
         %
         [task.readables.dotsReadableEye.windowSize] = deal(task.settings.gazeWindowSize);
         [task.readables.dotsReadableEye.windowDur]  = deal(task.settings.gazeWindowDuration);
         
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
         
         % ---- Have it loop forever until instructed to stop
         %
         task.iterations = inf;
      end
   end
end