classdef topsTreeNodeTask2AFCSwitch < topsTreeNodeTask
   % @class topsTreeNodeTask2AFCSwitch
   %
   % Simple 2AFC task with change-points.
   %
   % DEPENDENCIES: uses dotsPlayableTonePTB, which uses several 
   %  Psychtoolbox files: 
   %     PsychPortAudio.m
   %     PsychPortAudio.mexmaci64
   %     PsychPortAudioTimingTest.m
   %     Screen.m
   %     Screen.mexmaci64
   %
   % For standard configurations, call:
   %  topsTreeNodeTask2AFCSwitch.getStandardConfiguration
   %
   % Otherwise:
   %
   %  1. Create an instance directly:
   %        task = topsTreeNodeTask2AFCSwitch();
   %
   %  2. Set properties.
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 12/10/19 created by jig from topsTreeNodeTaskSimpleBandit
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties, put in a struct for convenience
      settings = struct( ...
         'blockMin',                   0,   ... % min hazard-block length (trials)
         'blockMax',                   0,   ... % max hazard-block length (trials)
         'blockHazard',                0.1, ... % p(block switch)
         'predictOrReport',            'Report', ... % duh
         'useDrawables',               true, ... % Use visual stimuli
         'usePlayables',               true, ... % Use auditory stimuli
         'checkFixation',              false, ... % Whether to use eye tracker to check
         'minimumRT',                  0.0, ...
         'fractionCongruent',          0.8);    % fraction of targets congurent with source
      
      % Task timing parameters, all in sec
      timing = struct( ...
         'waitFix',                    5.0, ...
         'waitNoFix',                  0.5, ...
         'waitBeforeStim',             0.1, ...
         'stimDuration',               1.0, ...
         'waitAfterStim',              0.1, ...
         'waitBeforeChoice',           0.1, ...
         'choiceTimeout',              5.0, ...
         'waitAfterChoice',            0.1, ...
         'minimumRT',                  0,   ...
         'interTrialInterval',         0.5);
      
      % Fields below are optional but if found with the given names
      %  will be used to automatically configure the task
      
      % independentVariables used by topsTreeNodeTask.makeTrials. Can
      % modify using setIndependentVariableByName and
      % setIndependentVariablesByName.
      %
      % Creates the array of trialData structures, using:
      %  name     ... list of independent variables
      %  values   ... array of values associated with each independent
      %                    variable
      %  priors   ... empty, or relative frequencies of each value for each
      %                    independent variable (automatically normalizes
      %                    to sum to 1).
      %
      %  Also uses:
      %     trialIterations property to determine the number
      %              of copies of each trial type to use
      %     trialIterationMethod property to determine the
      %              ordering of the trials (in trialIndices)
      independentVariables = struct( ...
         'hazard',   struct('values', [0.10 0.30 0.90]));
      
      % dataFieldNames is a cell array of string names used as trialData fields
      % state and stim are 1/2
      trialDataFields = {'fixationOn', 'drawOn', 'playOn', 'drawOff', ...
         'instructionOn', 'choice', 'choiceTime', 'RT', 'fixationOff', ...
         'stim', 'state', 'totalCorrect', 'totalChoices'};
      
      % Drawables settings
      drawable = struct( ...
         ...
         ...   % Stimulus ensemble and settings
         'stimulusEnsemble',           struct( ...
         ...
         ...   % Drawable A settings
         'stimulusA',                  struct(     ...
         'fevalable',                  @dotsDrawableImages, ...
         'settings',                   struct(     ...
         'fileNames',                  {{'bird.jpg'}}, ...
         'height',                     15)),  ...
         ...
         ...   % Drawable B settings
         'stimulusB',                  struct(     ...
         'fevalable',                  @dotsDrawableImages, ...
         'settings',                   struct(     ...
         'fileNames',                  {{'bird.jpg'}}, ...
         'height',                     8)), ...
         ...
         ...   % Fixation settings
         'fixation',                   struct( ...
         'fevalable',                  @dotsDrawableTargets, ...
         'settings',                   struct( ...
         'nSides',                     4,                ...
         'width',                      1.0.*[2.0 0.2],   ...
         'height',                     1.0.*[0.2 2.0],   ...
         'colors',                     [1 0 0]))));
      
      % Playable settings
      playable = struct( ...
         ...
         ...   % Playable A settings
         'stimulusA',                  struct(     ...
         'fevalable',                  @dotsPlayableTonePTB, ...
         'settings',                   struct(     ...
         'frequency',                  200,        ...
         'duration',                   1.0)),      ...
         ...
         ...   % Playable B settings
         'stimulusB',                  struct(     ...
         'fevalable',                  @dotsPlayableTonePTB, ...
         'settings',                   struct(     ...
         'frequency',                  1000,        ...
         'duration',                   1.0)));
      
      % Readable settings
      readable = struct( ...
         ...
         ...   % The readable object
         'reader',                     struct( ...
         ...
         'copySpecs',                  struct( ...
         ...
         ...    % Button box (this is actually a HIDKeyboard, so you should
         ...    %    list this before the keyboard to make sure the correct
         ...    %    class is mapped
         'dotsReadableHIDButtons',     struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseA', 'choseB'}, ...
         'component',                  {'Button1', 'Button2'})}}), ...
         ...
         ...   % Keyboard events
         'dotsReadableHIDKeyboard',    struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseA', 'choseB'}, ...
         'component',                  {'KeyboardF', 'KeyboardJ'})}}), ...
         ...
         ...   % Gamepad
         'dotsReadableHIDGamepad',   	struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseA', 'choseB'}, ...
         'component',                  {'Trigger1', 'trigger2'})}}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy',          struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseA', 'choseB'}, ...
         'component',                  {'Dummy1', 'Dummy2'})}}))), ...
         ...
         ...   % The eye tracker object, if being used
         'eye',                        struct( ...
         ...
         'copySpecs',                  struct( ...
         ...
         ...   % The gaze windows
         'dotsReadableEye',            struct( ...
         'bindingNames',               'stimulusEnsemble', ...
         'prepare',                    {{@updateGazeWindows}}, ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'holdFixation', 'brokeFixation'}, ...
         'ensemble',                   {'fixationEnsemble', 'fixationEnsemble'}, ... % ensemble object to bind to
         'ensembleIndices',            {[1 1], [1 1]}, ...
         'isInverted',                 {0, 1})}}))));
      
      % Feedback messages
      message = struct( ...
         ...
         'message',                    struct( ...
         ...
         ...   Instructions
         'Instructions',               struct( ...
         'text',                       'Instructions', ...
         'speakText',                  true, ...
         'duration',                   1.0, ...
         'pauseDuration',              0.5, ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Cue to predict
         'Predict',                    struct(  ...
         'text',                       'Predict'), ...
         ...
         ...   Cue to report
         'Report',                     struct(  ...
         'text',                       'Report')));
   end
   
   methods
      
      %% Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTask2AFCSwitch(varargin)
         
         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(mfilename, varargin{:});
      end
      
      %% Start task method
      function startTask(self)
         
         % ---- Initialize the state machine
         %
         self.initializeStateMachine();
         
         % ---- Set up block switches
         %
         self.incrementTrialMethod            = 'hazard';
         self.incrementTrial.hazard.rate      = self.settings.blockHazard;
         self.incrementTrial.hazard.minTrials = self.settings.blockMin;
         self.incrementTrial.hazard.maxTrials = self.settings.blockMax;
         
         % ---- Set up readables
         %
         % Check for eye helper
         if ~isfield(self.helpers, 'eye') || isempty(self.helpers.eye.theObject)
            self.settings.checkFixation = false;
         end
         
         % ---- Show task-specific instructions
         %         
         if strcmpi(self.settings.predictOrReport, 'predict')
            self.settings.predictOrReport = 'Predict';
            self.helpers.message.setText('Instructions', ...
               {'Predict the identity of the next stimulus'});
         else
            self.settings.predictOrReport = 'Report';
            self.helpers.message.setText('Instructions', ...
               {'Report the identity of the previous stimulus'});
         end
         self.helpers.message.show('Instructions');
      end
      
      %% Overloaded finish task method
      function finishTask(self)
      end
      
      %% Overloaded start trial method
      %
      % Put stuff here that you want to do at the beginning of each
      %  trial
      function startTrial(self)
         
         % ---- Get the trial
         %
         trial = self.getTrial();
         
         %---- Set up trial struct
         %
         % Initialize just the first time we use this trial
         if ~isfinite(trial.totalCorrect)
               
            % We iterate through each "trial" several times, so at the
            % beginning we need to reset these counters
            trial.totalCorrect = 0;
            trial.totalChoices = 0;
            trial.state = randi(2);            
         else
            
            % Clean up fields that get saved per trial
            for ii = 1:length(self.trialDataFields)-3
               trial.(self.trialDataFields{ii}) = nan;
            end
         end
         
         % Switch/keep state based on hazard
         if rand() <= trial.hazard
            trial.state = bitxor(trial.state, 3);
         end
         
         % Get stim location from state
         if rand() <= self.settings.fractionCongruent
            trial.stim = trial.state;
         else
            trial.stim = bitxor(trial.state, 3);
         end
         
         % Re-save the trial
         self.setTrial(trial);
         
         % ---- Prepare the playables
         %
         if self.settings.usePlayables
            self.helpers.stimulusA.theObject.prepareToPlay();
            self.helpers.stimulusB.theObject.prepareToPlay();
         end
         
         % ---- Set up readable isActive flags
         %
         if self.settings.checkFixation
            self.helpers.eye.theObject.setEventsActiveFlag({'holdFixation', 'brokeFixation'}, 'all');
         end
         self.helpers.reader.theObject.setEventsActiveFlag({'choseA', 'choseB'}, 'all');
         
         % ---- Use the task ITI
         %
         self.interTrialInterval = self.timing.interTrialInterval;
         
         % ---- Show information about the trial
         %
         % Task information
         taskString = sprintf('%s (ID=%d, task %d/%d)', self.name, ...
            self.taskID, self.taskIndex, length(self.caller.children));         
         
         % Trial information
         trialString = sprintf('Trial %d(%d)/%d: Correct=%d/%d', ...
            self.trialCount, self.incrementTrial.counter, numel(self.trialData), ...
            trial.totalCorrect, trial.totalChoices);
         
         % Show the information
         self.updateStatus(taskString, trialString);
      end
      
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
      end
      
      %% Show stimulus
      %
      function showStimulus(self)
         
         % ---- Get the trial
         %
         trial = self.getTrial();
         
         % ---- Possibly show the visual stimulus         
         %
         if self.settings.useDrawables
            self.helpers.stimulusEnsemble.draw({[trial.stim 3], []}, ...
               self, 'drawOn');
         end
         
         % ---- Possibly play the auditory stimulus         
         %
         if self.settings.usePlayables            
            self.helpers.(['stimulus' 64+trial.stim]).startPlaying( ...
               self, 'playOn');
         end
      end
      
      %% Hide stimulus
      %
      function hideStimulus(self)
         
         % ---- Possibly hide the visual stimulus
         %
         if self.settings.useDrawables
            self.helpers.stimulusEnsemble.draw({[], [1 2]}, ...
               self, 'drawOff');
         end
      end
      
      %% Check for choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function nextState = checkForChoice(self, events, eventTag, nextStateAfterChoice)
         
         % ---- Check for event
         %
         eventName = self.helpers.reader.readEvent(events, self, eventTag);
         
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
         nextState = nextStateAfterChoice;
         
         % ---- Save trial info
         % 
         % Get current task/trial and set/save RT, choice
         trial        = self.getTrial();
         trial.RT     = trial.choiceTime - trial.instructionOn;
         trial.choice = 1+double(strcmp(eventName, 'choseB'));
         
         % Mark as correct/error (with respect to largest reward side)
         trial.totalChoices = trial.totalChoices + 1;
         trial.totalCorrect = trial.totalCorrect + double( ...
            trial.choice == trial.stim);
         
         % Re-save the trial
         self.setTrial(trial);
      end
   end
   
   methods (Access = protected)
      
      %% configureStateMachine method
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         % Draw
         blanks = {@dotsTheScreen.blankScreen};
         showfp = {@draw, self.helpers.stimulusEnsemble, {3, [1 2]}, self, 'fixationOn'};
         showst = {@showStimulus, self};
         hidest = {@hideStimulus, self};
         showi  = {@show, self.helpers.message, self.settings.predictOrReport, self, 'instructionOn'};
         
         % Read
         chkchc = {@checkForChoice, self, {'choseA' 'choseB'}, 'choiceTime', 'waitAfterChoice'};
         
         % ---- Conditional check for fixation
         %
         if self.settings.checkFixation
            chkeyef = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
            chkeyeb = {@getNextEvent, self.helpers.reader.theObject, false, {'brokeFixation'}};
            nextFix = 'checkFixation';
         else
            chkeyef = {};
            chkeyeb = {};
            nextFix = 'noCheckFixation';
         end
                  
         % ---- Timing variables, read directly from the timing property struct
         %
         t = self.timing;
         
         % ---- The Stimulus state machine
         %
         stimStates = {...
            'name'               'entry'  'input'  'timeout'            'exit'   'next'         ; ...
            'showFP'             showfp   {}       0                    {}       nextFix        ; ...            
            'checkFixation'      {}       chkeyef  t.waitFix            {}       'retry'        ; ...
            'retry'              blanks   {}       t.interTrialInterval {}       'checkFixation'; ...            
            'noCheckFixation'    {}       {}       t.waitNoFix          {}       'holdFixation' ; ...
            'holdFixation'       {}       chkeyeb  t.waitBeforeStim     {}       'showStim'     ; ...
            'showStim'           showst   chkeyeb  t.stimDuration       hidest   'waitAfterStim'; ...
            'waitAfterStim'      {}       chkeyeb  t.waitAfterStim      {}       'blank'        ; ...
            'blank'              blanks   {}       0                    {}       ''             ; ...
            };
         
         % ---- The Response state machine
         %
         responseStates = {...
            'name'               'entry'  'input'  'timeout'            'exit'   'next'         ; ...
            'waitBeforeChoice'   blanks   {}       t.waitBeforeChoice   {}       'getChoice'    ; ...            
            'getChoice'          showi    chkchc   t.choiceTimeout      {}       'waitBeforeChoice' ; ...
            'waitAfterChoice'    {}       {}       t.waitAfterChoice    {}       ''             ; ...
            };

         % ---- Add state machines in appropriate order
         %
         if strcmp(self.settings.predictOrReport, 'predict')
            
            % Prediction task: first response, then stimulus
            self.addStateMachine(responseStates);
            self.addStateMachine(stimStates);
         else
            
            % Report task: first stimulus, then response
            self.addStateMachine(stimStates);
            self.addStateMachine(responseStates); 
         end
      end
   end
   
   methods (Static)
      
      %% ---- Utility for defining standard configurations
      %
      function task = getStandardConfiguration(varargin)
         
         % ---- Get the task object, with optional property/value pairs
         task = topsTreeNodeTask2AFCSwitch(varargin{:});
      end
      
      %% ---- Utility for getting test configuration
      %
      function task = getTestConfiguration()
         
         task = topsTreeNodeTask2AFCSwitch();
         task.settings.blockMin = 2;
         task.settings.blockMax = 2;
         % task.independentVariables.hazard.values = 0.5;
         task.message.message.Instructions.text = {'Testing', 'topsTreeNodeTask2AFCSwitch'};
      end
   end
end