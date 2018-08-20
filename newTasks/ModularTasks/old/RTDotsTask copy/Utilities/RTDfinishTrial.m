function RTDfinishTrial(datatub)
% function RTDfinishTrial(datatub)
%
% RTD = Response-Time Dots
%
% Fevalable called at the end of the stateMachine. This code is appropriate
% for both dots and saccade tasks (althogh
%
% Inputs:
%   datatub    -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
%
% Created 5/11/18 by jig

%% ---- Get current task/trial
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task  = datatub{'Control'}{'currentTask'};
trial = task.trialData(task.trialIndex);

%% ---- Save times
% use the screen ensemble to get the (possibly remote) screen time
[trial.time_local_trialFinish, trial.time_screen_trialFinish, ~, ...
   trial.time_ui_trialFinish] = RTDsyncTiming( ...
   datatub{'Graphics'}{'screenEnsemble'}, datatub{'Control'}{'userInputDevice'});
task.trialData(task.trialIndex) = trial;

%% ---- Save the current trial in the DataLog
%  We do this even if no choice was made, in case later we want to re-parse
%     the UI data
topsDataLog.logDataInGroup(trial, 'trial');

%% ---- Call task.incrementTrialIndex to find the next trial
%
% Argument is a flag indicating whether or not to repeat the trial
task.updateTrial(trial.correct<0)