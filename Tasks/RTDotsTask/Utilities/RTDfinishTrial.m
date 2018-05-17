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
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
ui = datatub{'Control'}{'ui'};

% Ask for the time from the screen object, but only accept it if it comes
% quickly
roundTrip = inf;
start = mglGetSecs;
timeout = false;
while roundTrip > 0.006 && ~timeout;
    before = mglGetSecs;
    screenTime = screenEnsemble.callObjectMethod(@getCurrentTime);
    after = mglGetSecs;
    roundTrip = after - before;
    timeout = (after-start) > 0.5;
end
trial.time_eye_trialFinish    = ui.getDeviceTime();
trial.time_screen_trialFinish = screenTime;
trial.time_local_trialFinish  = mean([before after]);
if timeout
    trial.time_is_confident = false;
end

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
    
    % Increment trial counter
    task.nodeData.currentTrial = task.nodeData.currentTrial + 1;
    
    % Check for new task
    if task.nodeData.currentTrial > size(task.nodeData.trialData, 1)
        
        % Stop running this task
        task.finish();
    end
    
    % Used in performance output, below
    if trial.choice == 0
        outcomeStr = 'ERROR';
        task.nodeData.totalError = task.nodeData.totalError + 1;
    else
        outcomeStr = 'CORRECT';
        task.nodeData.totalCorrect = task.nodeData.totalCorrect + 1;
    end
end

%% ---- Print performance stats
disp(sprintf('  %s (%d correct, %d error)', ...
    outcomeStr, task.nodeData.totalCorrect, task.nodeData.totalError))
disp(' ')
