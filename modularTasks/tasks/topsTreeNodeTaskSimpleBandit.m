classdef topsTreeNodeTaskSimpleBandit < topsTreeNodeTask
   % @class topsTreeNodeTaskSimpleBandit
   %
   % Simple two-armed bandit task with block-wise changes in reward
   %  probabilities.
   %
   % For standard configurations, call:
   %  topsTreeNodeTaskSimpleBandit.getStandardConfiguration
   %
   % Otherwise:
   %  1. Create an instance directly:
   %        task = topsTreeNodeTaskSimpleBandit();
   %
   %  2. Set properties. These are required:
   %        task.drawables.screenEnsemble
   %        task.helpers.readers.theObject
   %     Others can use defaults
   %
   %  3. Add this as a child to another topsTreeNode
   %
   % 5/18/19 created by jig
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties, put in a struct for convenience
      settings = struct( ...
         'blockChangeHazard',          0.2, ... %
         'blockChangeMin',             4,  ... % min trials before switch
         'blockChangeMax',             8,  ... % max trials before switch
         'targetDistance',             8);
      
      % Task timing parameters, all in sec
      timing = struct( ...
         'choiceTimeout',              5.0, ...
         'minimumRT',                  0, ...
         'pauseAfterChoice',           0.2, ...
         'showFeedback',               1.0, ...
         'interTrialInterval',         1.5);
      
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
         'probabilityLeft', struct('values', [0.10 0.35 0.65 0.90], 'priors', []));
      
      % dataFieldNames is a cell array of string names used as trialData fields
      trialDataFields = {'choice', 'rewarded', 'RT', 'stimOn', 'choiceTime', ...
         'feedbackOn', 'totalCorrect', 'totalChoices'};
            
      % Targets settings
      targets = struct( ...
         ...
         ...   % The target helper
         'targets',                    struct( ...
         ...
         ...   % Target helper properties
         'showDrawables',              true, ...
         'showLEDs',                   true, ...
         ...
         ...   % Left card
         'leftCard',                   struct(  ...
         'fevalable',                  @dotsDrawableImages, ...
         'settings',                   struct( ...
         'fileNames',                  {{'cardBlue.jpg'}}, ...
         'height',                     15, ...
         'colors',                     [0 0 1])), ...
         ...
         ...   % Right card
         'rightCard',                  struct(  ...
         'fevalable',                  @dotsDrawableImages, ...
         'settings',                   struct( ...
         'fileNames',                  {{'cardRed.jpg'}}, ...
         'height',                     15, ...
         'colors',                     [1 0 0]))));
      
      % Playable settings
      playable = [];
      
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
         'name',                       {'choseLeft', 'choseRight'}, ...
         'component',                  {'Button1', 'Button2'})}}), ...
         ...
         ...   % Keyboard events
         'dotsReadableHIDKeyboard',    struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseLeft', 'choseRight'}, ...
         'component',                  {'KeyboardF', 'KeyboardJ'})}}), ...
         ...
         ...   % Gamepad
         'dotsReadableHIDGamepad',   	struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseLeft', 'choseRight'}, ...
         'component',                  {'Trigger1', 'trigger2'})}}), ...
         ...
         ...   % Dummy to run in demo mode
         'dotsReadableDummy',          struct( ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseLeft', 'choseRight'}, ...
         'component',                  {'Dummy1', 'Dummy2'})}}))));
      
      % Feedback messages
      message = struct( ...
         ...
         'message',                     struct( ...
         ...
         ...   Instructions
         'Instructions',               struct( ...
         'text',                       {'Choose the currently rewarded card. It is not always rewarded, and it can switch occasionally.'}, ...
         'speakText',                  true, ...
         'duration',                   1.0, ...
         'pauseDuration',              0.5, ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Correct
         'Correct',                    struct(  ...
         'text',                       'Good choice', ...
         'playable',                   'cashRegister.wav', ...
         'bgStart',                    [0 0.6 0], ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   Error
         'Error',                      struct(  ...
         'text',                       'Bad choice', ...
         'playable',                   'buzzer.wav', ...
         'bgStart',                    [0.6 0 0], ...
         'bgEnd',                      [0 0 0]), ...
         ...
         ...   No choice
         'No_choice',                  struct(  ...
         'text',                       'No choice - please try again!')));
   end
   
   methods
      
      %% Constuct with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTaskSimpleBandit(varargin)
         
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
         self.incrementTrial.hazard.rate      = self.settings.blockChangeHazard;
         self.incrementTrial.hazard.minTrials = self.settings.blockChangeMin;
         self.incrementTrial.hazard.maxTrials = self.settings.blockChangeMax;
         
         % ---- Show task-specific instructions
         %
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
            
            % Here we can also check/modify the trial order.
            % Make sure very first condition is easy
            if self.trialCount==1
               vals = [self.trialData(self.trialIndices).probabilityLeft];
               
               % Find the index of the first easy trial
               if randi(2) == 1
                  mi = find(vals==max(vals), 1);
               else
                  mi = find(vals==min(vals), 1);
               end
               
               if mi ~= 1
                  
                  % Swap the easy trial to the beginning
                  tmpi = self.trialIndices(mi);
                  self.trialIndices(mi) = self.trialIndices(1);
                  self.trialIndices(1)  = tmpi;
                  
                  % Get the updated trial
                  trial = self.getTrial();
               end
            end
            
            % We iterate through each "trial" several times, so at the
            % beginning we need to reset these counters
            trial.totalCorrect = 0;
            trial.totalChoices = 0;
         end
         
         % Clear the fields that get saved per trial
         for ii = 1:length(self.trialDataFields)-2
            trial.(self.trialDataFields{ii}) = nan;
         end
         
         % Re-save the trial
         self.setTrial(trial);
         
         % ---- Get the stimulus ensemble and set horizontal position using
         %        settings.targetDistance
         %
         self.helpers.targets.set('leftCard',  'x', -self.settings.targetDistance);
         self.helpers.targets.set('rightCard', 'x',  self.settings.targetDistance);
         
         % ---- Use the task ITI
         %
         self.interTrialInterval = self.timing.interTrialInterval;

         % ---- Show information about the trial
         %
         % Task information
         taskString = sprintf('%s (ID=%d, task %d/%d)', self.name, ...
            self.taskID, self.taskIndex, length(self.caller.children));
         
         % Trial information
         trialString = sprintf('Trial %d(%d)/%d: Rews=[%.0f %.0f], Correct=%d/%d', ...
            self.trialCount, self.incrementTrial.counter, numel(self.trialData), ...
            trial.probabilityLeft*100.0, (1-trial.probabilityLeft)*100.0, ...
            trial.totalCorrect, trial.totalChoices);
         
         % Show the information
         self.updateStatus(taskString, trialString);
      end
      
      %% Finish Trial
      %
      % Could add stuff here
      function finishTrial(self)
      end
      
      %% Check for choice
      %
      % Save choice/RT information and set up feedback for the dots task
      function nextState = checkForChoice(self, events, eventTag, nextStateAfterChoice)
         
         % ---- Check for event
         %
         eventName = self.helpers.reader.readEvent(events, self, eventTag);
         
         % Default return
         nextState = [];

         % Nothing... keep checking
         if isempty(eventName)
            return
         end
         
         % ---- Check for min RT
         % 
         % Get current task/trial
         trial = self.getTrial();
         RT = trial.choiceTime - trial.stimOn;
         if RT < self.timing.minimumRT
            return
         end
         
         % ---- Good choice!
         %
         % Override completedTrial flag
         self.completedTrial = true;
         
         % Jump to next state when done
         nextState = nextStateAfterChoice;
         
         % Save the choice, correct/error, RT
         trial.choice = double(strcmp(eventName, 'choseRight'));
         
         % Check to give reward
         if (trial.choice == 0 && rand() <= trial.probabilityLeft) || ...
               (trial.choice == 1 && rand() > trial.probabilityLeft)
            trial.rewarded = 1;
         else
            trial.rewarded = 0;
         end
         
         % Mark as correct/error (with respect to largest reward side)
         trial.totalChoices = trial.totalChoices + 1;
         trial.totalCorrect = trial.totalCorrect + double( ...
            (trial.choice==0 && trial.probabilityLeft>=0.5) || ...
            (trial.choice==1 && trial.probabilityLeft< 0.5));
         
         % Compute/save RT
         trial.RT = RT;
         
         % Re-save the trial
         self.setTrial(trial);
      end
      
      %% Show feedback
      %
      function showFeedback(self)
         
         % ---- Show trial feedback
         %
         trial = self.getTrial();
         
         % Check for outcome
         if ~self.completedTrial
            messageGroup = 'No_choice';
         elseif trial.rewarded==1
            messageGroup = 'Correct';
         else
            messageGroup = 'Error';
         end
         
         % --- Show trial feedback in gui
         %
         trialString = sprintf('Trial %d(%d)/%d: choice=%d (%s)', ...
            self.trialCount, self.incrementTrial.counter, numel(self.trialData), ...
            trial.choice, messageGroup);
         self.updateStatus([], trialString); % just update the second one
         
         % ---- Show trial feedback on the screen
         %
         self.helpers.message.show(messageGroup);
      end
   end
   
   methods (Access = protected)
      
      %% configureStateMachine method
      %
      function initializeStateMachine(self)
         
         % ---- Fevalables for state list
         %
         blanks = {@blank, self.helpers.targets};
         chkuic = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choiceTime', 'blank'};
         showfb = {@showFeedback, self};
         shows  = {@show, self.helpers.targets, {[1 2], []}, self, 'stimOn'};
 
         % ---- Timing variables, read directly from the timing property struct
         %
         t = self.timing;
         
         % ---- Make the state machine
         %
         % Note that the startTrial routine sets the target location and the 'next'
         % state after holdFixation, based on VGS vs MGS task
         states = {...
            'name'         'entry'  'input'  'timeout'             'exit'  'next'            ; ...
            'showStimuli'  shows    chkuic   t.choiceTimeout       {}      'blank'           ; ...
            'blank'        {}       {}       t.pauseAfterChoice    blanks  'showFeedback'    ; ...
            'showFeedback' showfb   {}       t.showFeedback        {}      'done'            ; ...
            'done'         {}       {}       0                     {}      ''                ; ...
            };
         
         % make the state machine
         self.addStateMachine(states);
      end
   end
   
   methods (Static)
      
      %% ---- Utility for defining standard configurations
      %
      function task = getStandardConfiguration(varargin)
         
         % ---- Get the task object, with optional property/value pairs
         task = topsTreeNodeTaskSimpleBandit(varargin{:});
      end
      
      %% ---- Utility for getting test configuration
      %
      function task = getTestConfiguration()
         task = topsTreeNodeTaskSimpleBandit();
         task.timing.minimumRT = 0.3;
         task.settings.blockChangeMin = 2;
         task.settings.blockChangeMax = 2;
         task.targets.targets.showLEDs = false;
         task.independentVariables.probabilityLeft.values = 0.5;
         task.message.message.Instructions.text = {'Testing', 'topsTreeNodeTaskSimpleBandit'};
      end
   end
end