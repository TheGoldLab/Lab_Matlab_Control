function RTDfinishTrial(datatub)
% function RTDfinishTrial(datatub)
%
% RTD = Response-Time Dots
%
% Fevalable called at the end of the stateMachine
%
% Inputs:
%   datatub    -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
%
% Created 5/11/18 by jig

%% ---- Get current task/trial information
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
trial = task.nodeData.trialData(task.nodeData.currentTrial);

%% ---- Always save the current trial in the DataLog
%  We do this even if no choice was made, in case later we want to re-parse
%     the UI data
topsDataLog.logDataInGroup(trial, 'trial');

%% ---- Save times
% use the screen ensemble to get the (possibly remote) screen time
[trial.time_local_trialFinish, ...
   trial.time_screen_trialFinish, ...
   ~, ...
   trial.time_ui_trialFinish] = ...
   RTDsyncTiming( ...
   datatub{'Graphics'}{'screenEnsemble'}, datatub{'Control'}{'ui'});

%% ---- Re-save the trial
task.nodeData.trialData(task.nodeData.currentTrial) = trial;

%% ---- Check for good response to prepare for next trial
if ~isfinite(trial.choice) || trial.choice < 0
    
    % NO CHOICE
    % Set repeat flag
    task.nodeData.repeatTrial = true;
    
    % Randomize current direction and save it in the current trial
    %  inside the task array, which is where we'll look for it later
    directions = datatub{'Input'}{'directions'};
    task.nodeData.trialData(task.nodeData.currentTrial).direction = ...
        directions(randperm(length(directions),1));
    
    % Used in performance output, below
    outcomeStr = 'NO CHOICE';
else
    
    % GOOD CHOICE
    % Unset repeat flag
    task.nodeData.repeatTrial = false;
    
    % Used in performance output, below
    if trial.choice == 0
        outcomeStr = 'ERROR';
        task.nodeData.totalError = task.nodeData.totalError + 1;
    else
        outcomeStr = 'CORRECT';
        task.nodeData.totalCorrect = task.nodeData.totalCorrect + 1;
    end
    
    % add RT to the outcome string (printed below)
    outcomeStr = cat(2, outcomeStr, sprintf(', RT=%.2f', ...
       task.nodeData.trialData(task.nodeData.currentTrial).RT));

    % Increment trial counter
    task.nodeData.currentTrial = task.nodeData.currentTrial + 1;
    
    % Check for new task
    if task.nodeData.currentTrial > size(task.nodeData.trialData, 1)
        
        % Stop running this task
        task.finish();
    end    
end

%% ---- Print performance stats
if task.nodeData.currentTrial > 1
   meanRT = nanmean([task.nodeData.trialData(1:(task.nodeData.currentTrial-1)).RT]);
else
   meanRT = 0;
end
disp(sprintf('  %s (%d correct, %d error, %.2f mean RT)', ...
    outcomeStr, task.nodeData.totalCorrect, task.nodeData.totalError, meanRT))
disp(' ')
