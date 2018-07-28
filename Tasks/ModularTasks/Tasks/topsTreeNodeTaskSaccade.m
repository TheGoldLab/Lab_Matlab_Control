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
         'trialsPerDirection',         10, ...
         'directions',                 0:45:315, ...
         'sendTTLs',                   false);
      
      % Task timing, all in sec
      timing = struct( ...
         'showInstructions',           10.0, ...
         'waitAfterInstructions',      0.5, ...
         'fixationTimeout',            5.0, ...
         'holdFixation',               0.5, ...
         'showFeedback',               1.0, ...
         'InterTrialInterval',         1.0, ...
         'VGSTargetDuration',          1.0, ...
         'MGSTargetDuration',          0.25, ...
         'MGSDelayDuration',           0.75, ...
         'saccadeTimeout',             5.0);
      
      % Drawables settings
      drawables = struct( ...
         ...
         ...   % Ensembles
         'screenEnsemble',             [],	...
         'stimulusEnsemble',           [],	...
         'textEnsemble',               [],	...
         ...
         ...   % General settings
         'settings',                    struct(  ...
         'targetOffset',                8,    ...
         'textOffset',                	2),   ...
         ...
         ...   % Fixation drawable settings
         'fixation',                   struct( ...
         'xCenter',                   	0,    ...
         'yCenter',                   	0,    ...
         'nSides',                    	4,                ...
         'width',                     	1.5.*[1.0 0.2], ...
         'height',                    	1.5.*[0.2 1.0], ...
         'colors',                    	[1 0 0]), ...
         ...
         ...   % Target drawable settings
         'target',                     struct(  ...
         'nSides',                     100,     ...
         'width',                      1.5,     ...
         'height',                     1.5));
      
      % Readable settings
      readables = struct( ...
         ...
         ...   % The readable object
         'userInput',                  [],      ...
         ...
         ...   % readable settings
         'settings',                   struct(  ...
         'bufferGaze',                 false),  ...
         ...
         ...   % Gaze windows
         'dotsReadableEye', struct( ...
         'name',              {'fixWindow', 'trgWindow'}, ...
         'eventName',         {'holdFixation', 'choseTarget'}, ...
         'windowSize',        {8, 8}, ...
         'windowDur',         {0.15, 0.15}, ...
         'ensemble',          {[], []}, ... % ensemble object to bind to
         'ensembleIndices',   {[1 1], [2 1]}), ... % object/item indices
         ...
         ...   % Keyboard events 
         'dotsReadableHIDKeyboard', struct( ...
         'name',        {'KeyboardSpacebar', 'KeyboardT', 'KeyboardC'}, ...
         'eventName',   {'holdFixation', 'choseTarget', 'calibrate'}));
   end
   
   properties (SetAccess = protected)
      
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
         
         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(varargin{:});
         
         % ---- Keep track of changes to certain property structs
         %
         %  This will eventually be useful for real-time updating
         self.addSetListeners({'drawables', 'readables'});
      end
      
      %% Start task method
      function startTask(self)
         
         % ---- Configure each element - separated for readability
         % 
         self.initializeDrawables();
         self.initializeReadables();
         self.initializeTrialData();
         self.initializeStateMachine();
         
         % ---- Set up gaze windows
         %
         if isa(self.readables.userInput, 'dotsReadableEye')
            
            % bind drawables to gaze windows
            [self.readables.dotsReadableEye.ensemble] = ...
               deal(self.drawables.stimulusEnsemble);
           
            % set up drift correction
            self.stateMachine.editStateByName('holdFixation', 'exit', ...
               {@resetGaze, self.readables.userInput, 1});
         end
         
         % ---- Show task-specific instructions
         %
         drawTextEnsemble(self.drawables.textEnsemble, ...
            self.drawables.settings.textStrings, ...
            self.timing.showInstructions, ...
            self.timing.waitAfterInstructions);
         
         % ---- Get the first trial
         %
         self.prepareForNextTrial();
      end
      
      %% Overloaded finish task method
      function finishTask(self)         
      end
      
      %% Start trial method
      function startTrial(self)
         
         % ---- Prepare components
         %
         self.prepareDrawables();
         self.prepareReadables();
         self.prepareStateMachine();
         self.prepareTrialData();
         
         % ---- Show information about the task/trial
         %
         trial = self.getTrial();
         self.statusStrings = { ...
            ... % Task info
            sprintf('%s (task %d/%d): mean RT=%.2f', ...
            self.name, self.taskID, ...
            length(self.caller.children), ...
            nanmean([self.trialData.RT])), ...
            ... % Trial info
            sprintf('Trial %d/%d, dir=%d', ...
            self.trialCount, numel(self.trialData)*self.trialIterations, ...
            trial.direction)};
         self.updateStatus(); % just update the second one
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
            self.repeatTrial = false;
            
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
         targetOffset = self.drawables.settings.targetOffset;
         self.drawables.stimulusEnsemble.setObjectProperty('xCenter', ...
            self.drawables.fixation.xCenter + targetOffset * cosd(trial.direction), 2);
         self.drawables.stimulusEnsemble.setObjectProperty('yCenter', ...
            self.drawables.fixation.yCenter + targetOffset * sind(trial.direction), 2);
         
         % ---- Conditionally update all stimulusEnsemble objects
         %
         if self.updateFlags.drawables
            
            % All other stimulus ensemble properties
            stimulusDrawables = {'fixation' 'target'};
            for dd = 1:length(stimulusDrawables)
               for ff = fieldnames(self.drawables.(stimulusDrawables{dd}))'
                  self.drawables.stimulusEnsemble.setObjectProperty(ff{:}, ...
                     self.drawables.(stimulusDrawables{dd}).(ff{:}), dd);
               end
            end
            
            % Unset the flag
            self.updateFlags.drawables = false;
         end
      end
      
      %% Prepare readables for this trial
      %
      function prepareReadables(self)
         
         % ---- Reset the events
         %
         % Check for update... if so, get the readables event update struct 
         %     based on the class type
         if self.updateFlags.readables
            classType = intersect(fieldnames(self.readables), ...
               cat(1, class(self.readables.userInput), ...
               superclasses(self.readables.userInput)));
            eventDefinitions = self.readables.(classType{:});
            self.updateFlags.readables = false;
         else
            eventDefinitions = [];
         end
         
         % call resetEvents with the struct to do the heavy lifting
         self.readables.userInput.resetEvents(true, eventDefinitions);
         
         % ---- Flush the UI
         %
         self.readables.userInput.flushData();
      end
      
      %% Prepare trialData for this trial
      %
      function prepareTrialData(self)
         
         % ---- Get the current trial
         %
         trial = self.getTrial();
         
         % ---- Set repeat flag, which must be overridden
         %
         self.repeatTrial = true;
         
         % ---- Get synchronization times
         %
         [trial.time_local_trialStart, ...
            trial.time_screen_trialStart, ...
            trial.time_screen_roundTrip, ...
            trial.time_ui_trialStart, ...
            trial.time_ui_roundTrip] = ...
            syncTiming(self.drawables.screenEnsemble, ...
            self.readables.userInput);
         
         % ---- Conditionally send TTL pulses (mod trial count)
         %
         if self.settings.sendTTLs
            [trial.time_TTLStart, trial.time_TTLFinish] = ...
               sendTTLsequence(mod(self.trialCount,4)+1);
         end
         
         % ---- Re-save the trial
         %
         self.setTrial(trial);
      end
      
      %% Prepare stateMachine for this trial
      %
      function prepareStateMachine(self)
         
         % ---- Update stateMachine to jump to VGS-/MGS- specific states
         %
         editStateByName(self.stateMachine, 'holdFixation', 'next', ...
            [self.name 'showTarget']);
      end
      
      %% Initialize drawables
      %
      function initializeDrawables(self)
         
         % ---- Check for screen
         %
         if isempty(self.drawables.screenEnsemble)
            error('topsTreeNodeTaskRTDots: missing screenEnsemble');
         end
         
         % ---- Initialize the stimulus ensemble
         %
         % Create a stimulus ensemble consisting of two objects:
         %  1. Fixation cue
         %  2. One target
         if isempty(self.drawables.stimulusEnsemble)
            
            % create the ensemble
            self.drawables.stimulusEnsemble = makeDrawableEnsemble('stimulusEnsemble', ...
               {dotsDrawableTargets(), dotsDrawableTargets()}, ...
               self.drawables.screenEnsemble);
         end
         
         % ---- Make the text ensemble
         %
         if isempty(self.drawables.textEnsemble)
            
            % Make two text objects
            self.drawables.textEnsemble = makeTextEnsemble('text', 2, ...
               self.drawables.settings.textOffset, self.drawables.screenEnsemble);
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.drawables = true;
      end
      
      %% Initalize user input devices
      %
      % Here we just make sure we have them ... don't actually configure
      % anything until the start() method
      function initializeReadables(self)
         
         % ---- Initalize the primary user input device
         %
         if isempty(self.readables.userInput)
            self.readables.userInput = dotsReadableHIDKeyboard();
         end
         
         % ---- Set flag to update first time through
         %
         self.updateFlags.readables = true;
      end
      
      %% Initalize trial data
      %
      function initializeTrialData(self)
         
         % ---- Make array of directions
         % 
         directions = repmat(self.settings.directions, ...
            self.settings.trialsPerDirection, 1);
         
         % ---- Make the trial data structure array
         %
         self.trialData = dealMat2Struct(self.trialData(1), ...
            'taskID', repmat(self.taskTypeID,1,numel(directions)), ...
            'trialIndex', 1:numel(directions), ...
            'direction', directions);
      end
      
      %% configureStateMachine method
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         dnow   = {@drawnow};
         blanks = {@callObjectMethod, self.drawables.screenEnsemble, @blank};
         chkuif = {@getNextEvent, self.readables.userInput, false, {'holdFixation'}};
         chkuib = {}; % {@getNextEvent, self.readables.userInput, false, {}}; % {'brokeFixation'}
         chkuic = {@getEventWithTimestamp, self, self.readables.userInput, {'choseTarget'}, 'choice'};
         showfx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 1, 2, 'fixOn'};
         showt  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, 2, [], 'targsOn'};
         hidet  = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], 2, 'targsOff'};
         hidefx = {@drawWithTimestamp, self, self.drawables.stimulusEnsemble, [], 1, 'fixOff'};
         showfb = {@drawWithTimestamp, self, self.drawables.textEnsemble, 1, [], 'fdbkOn'};
         sch    = @(x)cat(2, {@setSaccadeChoice, self}, x);
         dce    = @defineCompoundEvent;
         gwfxw  = {dce, self.readables.userInput, {'fixWindow', ...
            'eventName', 'holdFixation', 'isInverted', false, 'isActive', true}};
         gwfxh  = {dce, self.readables.userInput, {'fixWindow', ...
            'eventName', 'brokeFixation', 'isInverted', true}};
         gwt    = {dce, self.readables.userInput, {'fixWindow', 'isActive', false}, ...
            {'trgWindow', 'isActive', true}};
         
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
         trialStates = {...
            'name'              'entry'  'input'  'timeout'  'exit'  'next'            ; ...
            'showFixation'      showfx   {}       0          {}      'waitForFixation' ; ...
            'waitForFixation'   gwfxw    chkuif   tft        {}      'blankNoFeedback' ; ...
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
            'done'              dnow     {}       iti        {}      ''                ; ...
            };
         
         % ---- Put stuff together in a stateMachine so that it will run
         %
         self.stateMachine = topsStateMachine();
         self.stateMachine.addMultipleStates(trialStates);
         self.stateMachine.startFevalable = {@self.startTrial};
         self.stateMachine.finishFevalable = {@self.finishTrial};
         
         % For debugging
         %self.stateMachine.addSharedFevalableWithName( ...
         %   {@showStateInfo}, 'debugStates', 'entry');
         
         % ---- Make a concurrent composite to interleave run calls
         %
         self.stateMachineComposite = topsConcurrentComposite('stateMachine Composite');
         self.stateMachineComposite.addChild(self.stateMachine);
         
         % ---- Add it as a child to the task
         %
         self.addChild(self.stateMachineComposite);
      end
   end
   
   methods (Static)
      
      %% ---- Utility for defining standard configurations
      %
      % name is string:
      %  'VGS' for visually guided saccade
      %  'MGS' for memory guided saccade
      %
      function task = getStandardConfiguration(name, trialsPerDirection, varargin)
         
         % ---- Get the task object, with optional property/value pairs
         task = topsTreeNodeTaskSaccade(name, varargin{:});
         
         % ---- Use given trials per direction
         %
         if ~isempty(trialsPerDirection)
            task.settings.trialsPerDirection = trialsPerDirection;
         end
         
         % ---- Instruction strings
         %
         switch name
            case 'VGS'
               task.drawables.settings.textStrings = { ...
                  'Look at the red cross. When it disappears,', ...
                  'look at the visual target.'};
            otherwise
               task.drawables.settings.textStrings = { ...
                  'Look at the red cross. When it disappears,', ...
                  'look at the remebered location of the visual target.'};
         end
      end
   end
end