function RTDupdateMeanRT(datatub)
% function RTDupdateMeanRT(datatub)
%
% RTD = Response-Time Dots
%
% Update meanRT between trials
%
% Inputs:
%  datatub  ... A topsGroupedList object containing experimental 
%                parameters as well as data recorded during the experiment.
% 
% 5/11/18 created by jig

%% ---- Get current task and associated data
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};

%% ---- Update reference RT
datatub{'Task'}{'referenceRT'} = nanmedian( ...
   [task.trialData(1:min(numel(task.trialData), task.trialCount)).RT]);