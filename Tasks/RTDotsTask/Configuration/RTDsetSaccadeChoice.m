function RTDsetSaccadeChoice(datatub, value)
% function RTDsetSaccadeChoice(datatub, value)
%
% RTD = Response-Time Dots
%
% Save choice/RT information and set up feedback for the dots task
%
% Created 5/11/18 by jig

%% ---- Get current task/trial and save the outcome value
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
trial = task.nodeData.trialData(task.nodeData.currentTrial);
trial.correct = value;

%% ---- Parse choice info
if value<0
   
   % NO CHOICE
   % Set repeat flag
   task.nodeData.repeatTrial = true;
   
   % Set feedback for no choice
   feedbackString = 'No choice';
else
   
   % GOOD CHOICE
   % Unset repeat flag
   task.nodeData.repeatTrial = false;
   
   % Set feedback
   task.nodeData.totalCorrect = task.nodeData.totalCorrect + 1;
   feedbackString = 'Correct';
   
   % Compute/save RT
   %  Remember that time_choice time is from the UI, whereas
   %    fixOff is from the remote computer, so we need to 
   %    account for clock differences
   trial.RT = (trial.time_choice - trial.time_ui_trialStart) - ...
       (trial.time_fixOff - trial.time_screen_trialStart);   
end

%% ---- Re-save the current trial
task.nodeData.trialData(task.nodeData.currentTrial) = trial;

%% ---- Set the feedback string
textEnsemble = datatub{'Graphics'}{'textEnsemble'};
inds = datatub{'Graphics'}{'text inds'};
textEnsemble.setObjectProperty('string', feedbackString, inds(1));

%% --- Print feedback in the command window
disp(sprintf('  %s, RT=%.2f (mean RT=%.2f)', ...
   feedbackString, trial.RT, ...
   nanmean([task.nodeData.trialData(1:task.nodeData.currentTrial).RT])))
