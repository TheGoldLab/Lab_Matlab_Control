function RTDsetDotsChoice(datatub, value)
% function RTDsetDotsChoice(datatub, value)
%
% RTD = Response-Time Dots
%
% Save choice/RT information and set up feedback for the dots task
%
% Created 5/11/18 by jig

%% ---- Get current task/trial and save the choice
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
trial = task.nodeData.trialData(task.nodeData.currentTrial);
task.nodeData.trialData(task.nodeData.currentTrial).choice = value;
   
%% ---- Parse choice info
if value<0
   
   % NO CHOICE
   % Set repeat flag
   task.nodeData.repeatTrial = true;
   
   % Set feedback for no choice
   feedbackString = 'No choice';
   
   % Randomize current direction and save it in the current trial
   %  inside the task array, which is where we'll look for it later
   directions = datatub{'Input'}{'directions'};
   trial.direction = directions(randperm(length(directions),1));
   
else
   
   % GOOD CHOICE
   % Unset repeat flag
   task.nodeData.repeatTrial = false;
   
   % Mark as correct/error
   trial.correct = double( ...
      (trial.choice==0 && trial.direction==180) || ...
      (trial.choice==1 && trial.direction==0));
   
   % Compute/save RT
   %  Remember that dotsOn time might be from the remote computer, whereas
   %  sacOn is from the local computer, so we need to account for clock
   %  differences
   trial.RT = trial.time_choice - (trial.time_local_trialStart + ...
      trial.time_dotsOn - trial.time_screen_trialStart);
   
   % Set up feedback string
   %  First Correct/error
   if trial.correct == 1
      feedbackString = 'Correct';
      task.nodeData.totalError = task.nodeData.totalError + 1;
   else
      feedbackString = 'Error';
      task.nodeData.totalCorrect = task.nodeData.totalCorrect + 1;
   end
   
   %  Second possibly feedback about speed
   if task.name(1) == 'S'
      if trial.RT <= datatub{'Task'}{'referenceRT'}
         feedbackString = cat(2, feedbackString, ', in time');
      else
         feedbackString = cat(2, feedbackString, ', too slow');
      end
   end
end

%% ---- Re-save the current trial
task.nodeData.trialData(task.nodeData.currentTrial) = trial;
   
%% ---- Set the feedback string
textEnsemble = datatub{'Graphics'}{'textEnsemble'};
inds = datatub{'Graphics'}{'text inds'};
textEnsemble.setObjectProperty('string', feedbackString, inds(1));

%% --- Print feedback in the command window
disp(sprintf('  %s, RT=%.2f (%d correct, %d error, %.2f mean RT)', ...
   feedbackString, trial.RT, task.nodeData.totalCorrect, ...
   task.nodeData.totalError, ...
   nanmean([task.nodeData.trialData(1:task.nodeData.currentTrial).RT])))
