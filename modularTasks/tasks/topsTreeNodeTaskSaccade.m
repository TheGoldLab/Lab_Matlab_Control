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
   %        task.helpers.readers.theObject
   %     Others can use defaults
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 5/28/18 created by jig
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties, put in a struct for convenience
      settings = struct( ...
         'targetDistance',             8);
      
      % Task timing parameters, all in sec
      timing = struct( ...
         'fixationTimeout',            5.0, ...
         'holdFixation',               0.75, ...
         'minimumRT',                  0.05, ...
         'holdTarget',                 0.75, ...
         'showFeedback',               1.0, ...
         'interTrialInterval',         1.5, ...
         'VGSTargetDuration',          1.25, ...
         'MGSTargetDuration',          0.25, ...
         'MGSDelayDuration',           1.0, ...
         'saccadeTimeout',             5.0);
      
      % Fields below are optional but if found with the given names
      %  will be used to automatically configure the task
      
      % independentVariables used by topsTreeNodeTask.makeTrials. Can
      % modify using setIndependentVariableByName and setIndependentVariablesByName
      independentVariables = struct( ...
         'direction',   struct('values', [0 180], 'priors', []));
      
      % dataFieldNames are used to set up the trialData structure
      trialDataFields = {'RT', 'correct', 'fixationOn', 'fixationStart', ...
         'targetOn', 'targetOff', 'fixationOff', 'choiceTime', 'feedbackOn'};
      
      % Drawables settings
      drawable = [];
      
      % Targets settings
      targets = struct( ...
         ...
         ...   % The target helper
         'targets',                    struct( ...
         ...
         ...   % Target helper properties
         'showDrawables',              true, ...
         'showLEDs',                   true, ...
         'onPlayables',                struct( ...
         'target',                     'location'), ...
         'offPlayables',               struct( ...
         'fixation',                   [1000 0.05 1]), ...
         ...
         ...   % Fixation drawable settings
         'fixation',                   struct( ...
         'fevalable',                  @dotsDrawableTargets,   ...
         'settings',                   struct( ...
         'nSides',                     4,                ...
         'width',                      3.0.*[1.0 0.1],   ...
         'height',                     3.0.*[0.1 1.0],   ...
         'colors',                     [1 0 0])),        ...
         ...
         ...   % Targets drawable settings
         'target',                     struct(   ...
         'fevalable',                  @dotsDrawableTargets,   ...
         'settings',                   struct(   ...
         'nSides',                     100,      ...
         'width',                      4,        ...
         'height',                     4,        ...
         'xCenter',                    10,       ...
         'colors',                     [0 1 0]))));
      
      % Readable settings
      readable = struct( ...
         ...
         ...   % The readable object
         'reader',                     struct( ...
         ...
         'copySpecs',                  struct( ...
         ...
         'dotsReadableEye',            struct( ...
         'bindingNames',               'stimulusEnsemble', ...
         'prepare',                    {{@updateGazeWindows}}, ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'breakFixation', 'choseTarget'}, ...
         'ensemble',                   {'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble'}, ... % ensemble object to bind to
         'ensembleIndices',            {[1 1], [1 1], [2 1]})}}), ...
         ...
         ...    % Button box (this is actually a HIDKeyboard, so you should
         ...    %    list this before the keyboard to make sure the correct
         ...    %    class is mapped
         'dotsReadableHIDButtons',     struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseTarget'}, ...
         'component',                  {'Button1', 'Button2'}, ...
         'isRelease',                  {true, false})}}), ...
         ...
         ...   % Keyboard events
         'dotsReadableHIDKeyboard',    struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseTarget'}, ...
         'component',                  {'KeyboardSpacebar', 'KeyboardT'}, ...
         'isRelease',                  {true, false})}}), ...
         ...
         ...   % Gamepad
         'dotsReadableHIDGamepad',   	struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseTarget'}, ...
         'component',                  {'Button1', 'Trigger1'}, ...
         'isRelease',                  {true, false})}}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy',          struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseTarget'}, ...
         'component',                  {'Dummy1', 'Dummy2'})}}))));
      
      % Feedback messages
      message = struct( ...
         ...       
         'message',                     struct( ...
         ...
         ...   Instructions
         'Instructions',               struct( ...         
         'text',                       2, ...
         'speakText',                  true, ...
         'duration',                   1, ...
         'pauseDuration',              0.5, ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Correct
         'Correct',                    struct(  ...
         'text',                       {{'Great!', 'y', 6}}, ...
         'images',                     {{'thumbsUp.jpg', 'y', -6}}, ...
         'playable',                   'cashRegister.wav', ...
         'bgStart',                    [0 0.6 0], ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Error
         'No_Choice',                  struct(  ...
         'text',                       'Try again!', ...
         'playable',                   'buzzer.wav', ...
         'bgStart',                    [0.6 0 0], ...
         'bgEnd',                      [0 0 0])));
   end
   
   methods
      
      %% Construct with name and property/value pairs optional
      %
      function self = topsTreeNodeTaskSaccade(varargin)
         
         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(mfilename, varargin{:});
      end
      
      %% Start task method
      function startTask(self)
         
         % ---- Check name
         %
         if ~strcmp(self.name, 'VGS') && ~strcmp(self.name, 'MGS')
            self.name = 'VGS';
         end
         
         % ---- Initialize the state machine
         %
         self.initializeStateMachine();
         
         % ---- Show the instructions
         %
         self.helpers.message.show('Instructions');
      end
      
      %% Overloaded finish task method
      function finishTask(self)
      end
      
      %% Overloaded start trial method
      function startTrial(self)
         
         % ---- Get the current trial
         %
         trial = self.getTrial();

         % ---- Set target location
         %
         self.helpers.targets.set('target', ...
            'anchor',   'fixation', ...
            'r',        self.settings.targetDistance, ...
            'theta',    trial.direction);
         
         % ---- Update stateMachine to jump to VGS-/MGS- specific states
         %
         self.stateMachine.editStateByName('holdFixation', ...
            'next',     [self.name 'showTarget']);
         
         % ---- Use the task ITI
         %
         self.interTrialInterval = self.timing.interTrialInterval;
               
         % ---- Show information about the task/trial
         %
         % Task information
         taskString = sprintf('%s (ID=%d, task %d/%d): mean RT=%.2f', self.name, ...
            self.taskID, task.taskIndex, length(self.caller.children), nanmean([self.trialData.RT]));
         
         % Trial information
         trialString = sprintf('Trial %d/%d, dir=%d', self.trialCount, ...
            numel(self.trialData), trial.direction);
         
         % Show the information
         self.updateStatus(taskString, trialString);
      end
      
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
      end
      
      %% Set Choice method
      %
      % Save choice/RT information
      function nextState = checkForChoice(self, events, eventTag)
         
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
         
         % Check for minimum RT
         RT = trial.choiceTime - trial.fixationOff;
         if RT < self.timing.minimumRT
            return
         end

         % ---- Good choice!
         %
         % Set completedTrial flag; save correct, RT
         self.completedTrial = true;
         self.setTrialData([], 'correct', 1);
         self.setTrialData([], 'RT', RT);
         nextState = eventName;         
      end
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % ---- Show trial feedback
         %
         trial = self.getTrial();
         if trial.correct == 1
            feedbackStr = 'Correct';
         else
            feedbackStr = 'No_Choice';
         end
         
         % --- Show trial feedback in gui
         %
         trialString = sprintf('Trial %d/%d, dir=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData), ...
            trial.direction, feedbackStr, trial.RT);
         self.updateStatus([], trialString); % just update the second one
         
         % ---- Show trial feedback on the screen
         %
         self.helpers.message.show(feedbackStr);
      end
   end
   
   methods (Access = protected)

      %% configureStateMachine method
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks = {@blank, self.helpers.targets};
         chkuif = {@readEvent, self.helpers.reader, {'holdFixation'}, self, 'fixationStart'};
         chkuib = {}; % {@getNextEvent, self.helpers.reader, false, {}}; % {'brokeFixation'}
         chkchc = {@checkForChoice, self, {'choseTarget'}, 'choiceTime'};
         dnow   = {@drawnow};
         hidefx = {@show, self.helpers.targets, {[], 1}, self, 'fixationOff'};
         hidet  = {@show, self.helpers.targets, {[], 2}, self, 'targetOff'};
         showfx = {@show, self.helpers.targets, {1,  2}, self, 'fixationOn'};
         showt  = {@show, self.helpers.targets, {2, []}, self, 'targetOn'};
         showfb = {@showFeedback, self};
         
         % drift correction
         hfdc  = {@reset, self.helpers.reader.theObject, true};
         
         % Activate/deactivate readable events
         gwfxw = {@setEventsActiveFlag, self.helpers.reader.theObject, 'holdFixation', 'choseTarget'};
         gwfxh = {};
         gwt   = {@setEventsActiveFlag, self.helpers.reader.theObject, 'choseTarget', 'holdFixation'};
         
         % ---- Timing variables, read directly from the timing property struct
         %
         t = self.timing;
         
         % ---- Make the state machine
         %
         % Note that the startTrial routine sets the target location and the 'next'
         % state after holdFixation, based on VGS vs MGS task
         states = {...
            'name'              'entry'  'input'  'timeout'             'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0                     {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   t.fixationTimeout     {}      'blankNoFeedback' ; ...
            'holdFixation'      gwfxh    chkuib   t.holdFixation        hfdc    'showTarget'      ; ... % Branch here
            'VGSshowTarget'     showt    chkuib   t.VGSTargetDuration   gwt     'hideFix'         ; ... % VGS
            'MGSshowTarget'     showt    chkuib   t.MGSTargetDuration   {}      'MGSdelay'        ; ... % MGS
            'MGSdelay'          hidet    chkuib   t.MGSDelayDuration    gwt     'hideFix'         ; ...
            'hideFix'           hidefx   chkchc   t.saccadeTimeout      {}      'blank'           ; ...
            'choseTarget'       {}       {}       0                     {}      'blank'           ; ...
            'blank',            {}       {}       t.holdTarget          blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       t.showFeedback        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0                     blanks  'done'            ; ...
            'done'              dnow     {}       0                     {}      ''                ; ...
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
      function task = getStandardConfiguration(name, varargin)
         
         % ---- Get the task object, with optional property/value pairs
         task = topsTreeNodeTaskSaccade(name, varargin{:});
         
         % ---- Instruction strings
         %
         switch name
            case 'VGS'
               task.message.message.Instructions.text = { ...
                  'Look at the central target until it disappears.', ...
                  'Then look at the other target.'};
            otherwise
               task.message.message.Instructions.text = { ...
                  'Look at the central target until it disappears.', ...
                  'Then look at the remembered location of the other target.'};
         end
      end
      
      %% ---- Utility for getting test configuration
      %
      function task = getTestConfiguration()
         task = topsTreeNodeTaskSaccade();
         task.name = 'VGS';
         task.timing.minimumRT = 0.3;
         task.targets.targets.showLEDs = false;
         task.independentVariables.direction.values = [0 180];
         task.message.message.Instructions.text = {'Testing', 'topsTreeNodeTaskSaccade'};
      end
   end
end