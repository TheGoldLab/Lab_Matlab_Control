classdef topsTreeNodeTaskSimpleBanditNoGraphics < topsTreeNodeTask
   % @class topsTreeNodeTaskSimpleBanditNoGraphics
   %
   % Simple two-armed bandit task with block-wise changes in reward
   %  probabilities, DOES NOT USE SNOW-DOTS GRAPHICS. This task is intended
   %  to be a learning tool.
   %
   % To run it, use:
   %  task = topsTreeNodeTaskSimpleBanditNoGraphics();
   %  task.run();
   %
   % 6/10/19 created by jig
   
   properties % (SetObservable) % uncomment if adding listeners
      
      % Trial properties, put in a struct for convenience
      settings = struct( ...
         'blockChangeHazard',          0.2, ... %
         'blockChangeMin',             4,  ...  % min trials before switch
         'blockChangeMax',             8);
      
      % Task timing parameters, all in sec
      timing = struct( ...
         'choiceTimeout',              0.4, ...
         'pauseAfterChoice',           0.2, ...
         'showFeedback',               1.0, ...
         'interTrialInterval',         1.0);
      
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
         'probabilityLeft',   struct('values', [0.10 0.35 0.65 0.90], 'priors', []));
      
      % dataFieldNames is a cell array of string names used as trialData fields
      trialDataFields = {'choice', 'rewarded', 'RT', 'stimOn', 'choiceTime', ...
         'feedbackOn', 'totalCorrect', 'totalChoices'};
      
      % Drawables settings
      drawable = [];
      
      % Playable settings
      playable = [];
      
      % Readable settings
      readable = struct( ...
         'reader',                     struct( ...
         'fevalable',                  @dotsReadableDummy, ...
         'start',                      {{@defineEventsFromStruct, struct( ...
         'name',                       {'choseLeft', 'choseRight'}, ...
         'component',                  {'Dummy1', 'Dummy2'})}}));
      
      % Feedback messages
      message = [];
   end
   
   methods
      
      %% Constuctor, with name optional.
      % @param name optional name for this object
      % @details
      % If @a name is provided, assigns @a name to this object.
      function self = topsTreeNodeTaskSimpleBanditNoGraphics(varargin)
         
         % ---- Make it from the superclass
         %
         self = self@topsTreeNodeTask(varargin{:});

         % ---- Set task type ID
         %
         self.taskTypeID = 4;
      end
      
      %% Start task method
      %
      % Always runs once when the task is starting
      function startTask(self)
         
         % ---- Initialize the state machine
         %
         % Define fevalables for state list
         chkuic = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choiceTime'};
         showfb = {@showFeedback, self};
         shows  = {@disp, 'Choose LEFT or RIGHT'};
         shown  = {@disp, 'In state noChoice'};
         showl  = {@disp, 'In state choseLeft'};
         showr  = {@disp, 'In state choseRight'};
         
         % Timing variables, read directly from the timing property struct
         t = self.timing;
         
         % Make the state machine
         states = {...
            'name'         'entry'  'input'  'timeout'             'exit'  'next'            ; ...
            'showStimuli'  shows    chkuic   t.choiceTimeout       {}      'noChoice'        ; ...
            'noChoice'     shown    {}       []                    {}      'blank'           ; ...
            'choseLeft'    showl    {}       []                    {}      'blank'           ; ...
            'choseRight'   showr    {}       []                    {}      'blank'           ; ...
            'blank'        {}       {}       t.pauseAfterChoice    {}      'showFeedback'    ; ...
            'showFeedback' showfb   {}       t.showFeedback        {}      'done'            ; ...
            'done'         {}       {}       []                    {}      ''                ; ...
            };
         
         % Add the state machine to the task
         self.addStateMachine(states);         
         
         % Turn on state debug flag
         % self.debugStates();

         % ---- Set up block switches
         %
         self.incrementTrialMethod            = 'hazard';
         self.incrementTrial.hazard.rate      = self.settings.blockChangeHazard;
         self.incrementTrial.hazard.minTrials = self.settings.blockChangeMin;
         self.incrementTrial.hazard.maxTrials = self.settings.blockChangeMax;
         
         % ---- Show start message
         %
         disp('Starting task')
      end
      
      %% Overloaded finish task method
      %
      % Always runs once when the task is ending
      function finishTask(self)
         
         % ---- Show finish message
         %
         disp('Finished task')
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
         
         % ---- Use the task ITI
         %
         self.interTrialInterval = self.timing.interTrialInterval;

         % ---- Show information about the trial
         %
         % Task information
         if ~isempty(self.caller)
            taskString = sprintf('%s (task %d/%d)', self.name, ...
               self.taskID, length(self.caller.children));
         else
            taskString = sprintf('%s (%d)', self.name, self.taskID);
         end
         
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
      function nextState = checkForChoice(self, events, eventTag)
         
         % ---- Check for event
         %
         nextState = self.helpers.reader.readEvent(events, self, eventTag);
         
         % Nothing... keep checking
         if isempty(nextState)
            return
         end
         
         % ---- Good choice!
         %
         % Override completedTrial flag
         self.completedTrial = true;

         % Get current task/trial
         trial = self.getTrial();
         
         % Save the choice, correct/error, RT
         trial.choice = double(strcmp(nextState, 'choseRight'));
         trial.totalChoices = trial.totalChoices + 1;
         
         % Check to give reward
         rv = rand() <= trial.probabilityLeft;
         trial.rewarded = (trial.choice == 0 && rv) || (trial.choice == 1 && ~rv);
         
         % Mark as correct/error (with respect to largest reward side)
         trial.totalCorrect = trial.totalCorrect + double( ...
            (trial.choice==0 && trial.probabilityLeft>=0.5) || ...
            (trial.choice==1 && trial.probabilityLeft< 0.5));
         
         % Compute/save RT
         trial.RT = trial.choiceTime - trial.stimOn;
         
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
            feedback = 'No choice -- try again';
         elseif trial.rewarded
            feedback = 'Rewarded!';
         else
            feedback = 'Not rewarded!';
         end
         
         % --- Show trial feedback
         %
         trialString = sprintf('Trial %d(%d)/%d: choice=%d (%s)', ...
            self.trialCount, self.incrementTrial.counter, numel(self.trialData), ...
            trial.choice, feedback);
         self.updateStatus([], trialString); % just update the second one
      end
   end
   
   methods (Static)
      
      %% ---- Utility for getting test configuration
      %
      function task = getTestConfiguration()
         
         task = topsTreeNodeTaskSimpleBanditNoGraphics();
         task.independentVariables.probabilityLeft.values = 0.5;
         task.settings.blockChangeMin = 2;
         task.settings.blockChangeMax = 2;
      end
   end
end