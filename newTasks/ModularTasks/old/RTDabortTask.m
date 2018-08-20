function RTDabortTask(datatub)
% function RTDabortTask(datatub)
%
% RTD = Response-Time Dots
%
% Skip to the end of the current task
%
% Inputs:
%   datatub - A topsGroupedList object containing experimental parameters
%              as well as data recorded during the experiment.
% 
% 5/11/18 created by jig

% Get the highest-level topsTreeNode and set isRunning=false for itself and
% all of its children

% turn off current task and main task
currentTask = datatub{'Control'}{'currentTask'};
currentTask.isRunning = false;
