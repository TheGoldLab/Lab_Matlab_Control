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
         'targetDistance',             8,    ...
         'textStrings',                '',   ...
         'SpeakDirection',             true, ...
         'playSoundAtFixOff',          true, ...
         'correctImage',               'thumbsUp.jpg',      ... % see topsTaskHelperFeedback
         'errorImage',                 [],   ...
         'correctPlayable',            'cash_register.wav', ...   
         'errorPlayable',              'buzzer.wav');
      
      % Task timing parameters, all in sec
      timing = struct( ...
         'showInstructions',           10.0, ...
         'waitAfterInstructions',      0.5, ...
         'fixationTimeout',            5.0, ...
         'holdFixation',               0.75, ...
         'showSmileyFace',             0,   ...
         'holdTarget',                 1.0, ...
         'showFeedback',               1.0, ...
         'interTrialInterval',         1.5, ...
         'VGSTargetDuration',          1.75, ...
         'MGSTargetDuration',          0.25, ...
         'MGSDelayDuration',           1.5, ...
         'saccadeTimeout',             5.0);
      
      % Fields below are optional but if found with the given names
      %  will be used to automatically configure the task
      
      % independentVariables used by topsTreeNodeTask.makeTrials. Can
      % modify using setIndependentVariableByName and setIndependentVariablesByName
      independentVariables = struct( ...
         'name',                       {'direction'},       ...
         'values',                     {0:90:270},          ...
         'priors',                     {[]});
      
      % dataFieldNames are used to set up the trialData structure
      trialDataFields = {'RT', 'correct', 'fixationOn', 'fixationStart', ...
         'targetOn', 'targetOff', 'fixationOff', 'choiceTime', 'feedbackOn'};
      
      % Drawables settings
      drawable = struct( ...
         ...
         ...   % The main stimulus ensemble
         'stimulusEnsemble',           struct(  ...
         ...
         ...   % Fixation drawable settings
         'fixation',                   struct( ...
         'fevalable',                  @dotsDrawableTargets,   ...
         'settings',                   struct( ...
         'nSides',                     4,                ...
         'width',                      3.0.*[1.0 0.1],   ...
         'height',                     3.0.*[0.1 1.0],   ...
         'colors',                     [1 1 1])),        ...
         ...
         ...   % Targets drawable settings
         'targets',                    struct(  ...
         'fevalable',                  @dotsDrawableTargets,   ...
         'settings',                   struct(   ...
         'nSides',                     100,      ...
         'width',                      4,      ...
         'height',                     4)), ...
         ...
         ...   % Smiley face for feedback
         'smiley',                     struct(  ...
         'fevalable',                  @dotsDrawableImages, ...
         'settings',                   struct( ...
         'fileNames',                  {{'smiley.jpg'}}, ...
         'height',                     2))));
      
      % Playable settings
      playable = struct( ...
         ...
         ... % Args are frequency (Hz), time (sec), scale factor
         ... % Note that calling makeTone calls prepareToPlay automatically, 
         ... %    otherwise that should be called explicitly before each trial
         'fixOffTone',                 struct( ...
         'fevalable',                  {{@dotsPlayableFastTone.makeTone, [1000 0.05 1]}}));
      
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
         ...    % Ashwin's magic buttons
         'dotsReadableHIDButtons',     struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseTarget'}, ...
         'component',                  {'KeyboardLeftShift', 'KeyboardRightShift'}, ...
         'isRelease',                  {true, false})}}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy',          struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'choseTarget'}, ...
         'component',                  {'auto_1', 'auto_2'})}}))));
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
         
         % ---- Initialize the state machine
         %
         self.initializeStateMachine();
         
         % ---- Show task-specific instructions
         %
         self.helpers.feedback.show( ...
            'text', self.settings.textStrings, ...
            'showDuration', self.timing.showInstructions, ...
            'backgroundEndColor', [0 0 0]);
         pause(self.timing.waitAfterInstructions);
      end
      
      %% Overloaded finish task method
      function finishTask(self)
      end
      
      %% Overloaded start trial method
      function startTrial(self)
         
         % ---- Prepare components
         %
         self.prepareDrawables();
         self.prepareReadables();
         self.prepareStateMachine();
         
         % ---- Show information about the task/trial
         %
         % Task information
         taskString = sprintf('%s (task %d/%d): mean RT=%.2f', self.name, ...
            self.taskID, length(self.caller.children), nanmean([self.trialData.RT]));
         
         % Trial information
         trial = self.getTrial();
         trialString = sprintf('Trial %d/%d, dir=%d', self.trialCount, ...
            numel(self.trialData)*self.trialIterations, trial.direction);
         
         % Show the information
         self.updateStatus(taskString, trialString); % just update the second one
      end
      
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
      end
      
      %% Set Choice method
      %
      % Save choice/RT information
      function setChoice(self)
         
         % ---- Good choice!
         %
         % Set completedTrial flag; save correct, RT
         trial = self.getTrial();
         self.completedTrial = true;
         self.setTrialData([], 'correct', 1);
         self.setTrialData([], 'RT', trial.choiceTime - trial.fixationOff);
         
         % ---- Possibly show smiley face
         if self.timing.showSmileyFace > 0
            self.helpers.stimulusEnsemble.draw({3, [1 2]});
         end
      end
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % ---- Show trial feedback
         %
         trial = self.getTrial();
         
         if trial.correct == 1
            feedbackStr = 'Correct';
            feedbackArgs = { ...
               'backgroundStartColor', [0 0.6 0], ...
               'text',  'Great!', ...
               'image', self.settings.correctImage, ...
               'sound', self.settings.correctPlayable};
         else
            feedbackStr = 'No choice';
            feedbackArgs = { ...
               'backgroundStartColor', [0.6 0 0], ...
               'text',  'No choice, please try again!', ...
               'image', self.settings.errorImage, ...
               'sound', []};
         end
         
         % --- Show trial feedback in gui
         %
         trialString = sprintf('Trial %d/%d, dir=%d: %s, RT=%.2f', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction, feedbackStr, trial.RT);
         self.updateStatus([], trialString); % just update the second one
         
         % ---- Show trial feedback on the screen
         %
         self.helpers.feedback.show(feedbackArgs{:});
      end
   end
   
   methods (Access = protected)
      
      %% Prepare drawables for this trial
      %
      function prepareDrawables(self)
         
         % ---- Get the current trial
         %
         trial = self.getTrial();
         
         % ---- Get the stimulus ensemble
         %
         stimulusEnsemble = self.helpers.stimulusEnsemble.theObject;
         
         % ---- Set target location
         %
         % Get x,y location of center of target
         newX = stimulusEnsemble.getObjectProperty('xCenter', 1) + ...
            self.settings.targetDistance * cosd(trial.direction);
         newY = stimulusEnsemble.getObjectProperty('yCenter', 1) + ...
            self.settings.targetDistance * sind(trial.direction);
         stimulusEnsemble.setObjectProperty('xCenter', newX, 2);
         stimulusEnsemble.setObjectProperty('yCenter', newY, 2);
         
         % ---- Possibly update feedback
         %
         if self.timing.showSmileyFace > 0
            
            % Set x, y
            stimulusEnsemble.setObjectProperty('x', newX, 3);
            stimulusEnsemble.setObjectProperty('y', newY, 3);
            
            % Prepare the smiley object
            stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow, [], 3);
         end         
      end
      
      %% Prepare readables for this trial
      %
      function prepareReadables(self)
         
         % ---- Inactivate all of the readable events
         %
         self.helpers.reader.theObject.deactivateEvents();
      end      
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)
         
         % ---- Update stateMachine to jump to VGS-/MGS- specific states
         %
         self.stateMachine.editStateByName('holdFixation', 'next', ...
            [self.name 'showTarget']);
      end
      
      %% Show target method (and possibly speak direction)
      %
      function showTarget(self)
         
         % ---- Show the target
         %
         draw(self.helpers.stimulusEnsemble, {2, []}, self, 'targetOn');

         % ---- Possibly speak direction
         %
         if self.settings.SpeakDirection
            
            % Get the current trial
            trial = self.getTrial();
            
            % Parse and speak direction
            switch trial.direction
               case 0
                  system('say right');
               case 90
                  system('say up');
               case 180
                  system('say left');
               case 270
                  system('say down');
            end
         end
      end
      
      %% configureStateMachine method
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         dnow   = {@drawnow};
         blanks = {@dotsTheScreen.blankScreen, [0 0 0]};
         chkuif = {@readEvent, self.helpers.reader, {'holdFixation'}, self, 'fixationStart'};
         chkuib = {}; % {@getNextEvent, self.helpers.reader, false, {}}; % {'brokeFixation'}
         chkuic = {@readEvent, self.helpers.reader, {'choseTarget'}, self, 'choiceTime'};
         setchc = {@setChoice, self};
         showt  = {@showTarget, self};
         showfx = {@draw, self.helpers.stimulusEnsemble, {1, [2 3]},  self, 'fixationOn'};
         hidet  = {@draw, self.helpers.stimulusEnsemble, {[], 2}, self, 'targetOff'};
         showfb = {@showFeedback, self};
         hidefx = {@draw, self.helpers.stimulusEnsemble, {[], 1}, self, 'fixationOff'};
         if self.settings.playSoundAtFixOff
            hidefx = {@fevalMany, {{@startPlaying, self.helpers.fixOffTone}, hidefx}};
         end
         
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
            'hideFix'           hidefx   chkuic   t.saccadeTimeout      {}      'blank'           ; ...
            'choseTarget',      setchc   {}       t.showSmileyFace      {}      'blank'           ; ...
            'blank'             {}       {}       t.holdTarget          blanks  'showFeedback'    ; ...
            'showFeedback'      showfb   {}       t.showFeedback        blanks  'done'            ; ...
            'blankNoFeedback'   {}       {}       0                     blanks  'done'            ; ...
            'done'              dnow     {}       t.interTrialInterval  {}      ''                ; ...
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
               task.settings.textStrings = { ...
                  'Look at the white cross. When it disappears,', ...
                  'look at the visual target.'};
            otherwise
               task.settings.textStrings = { ...
                  'Look at the white cross. When it disappears,', ...
                  'look at the remebered location of the visual target.'};
         end
      end
   end
end