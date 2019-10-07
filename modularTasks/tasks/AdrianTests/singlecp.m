function singlecp(subject_code, experiment_day, probCP, dump_folder)
% function to launch single CP Reversing Dots task
% 
% ARGS:
%   subject_code     --  string that identifies subject uniquely, e.g. 'S4'
%   experiment_day   --  integer counting the days of experimentation with this subject 
%   probCP           --  numeric value
%   dump_folder      --  e.g '/Users/adrian/Documents/MATLAB/projects/Lab_Matlab_Control/modularTasks/tasks/AdrianTests/'

%
% This function attempts to implement the following rules:
%  1. If experiment_day is > 1, checks that probCP alternates across days 
%  2. Check whether a previous session on the same day contains relevant
%     Quest info.
%

topNode = topsTreeNodeTopNode('oneCP');

topNode.addHelpers('screenEnsemble',  ...
   'displayIndex',      1, ...
   'remoteDrawing',     false, ...
   'topNode',           topNode);

topNode.addReadable('dotsReadableHIDKeyboard');

pauseBeforeTask = -1; % -1 means wait for keypress -- see topsTreeNode.pauseBeforeTask

cpDotsTask = topsTreeNodeTaskReversingDots4AFC('cpDots');
cpDotsTask.taskID = 1;
cpDotsTask.independentVariables='ReversingDotsTestTrials.csv'; 
cpDotsTask.trialIterationMethod='sequential';
cpDotsTask.pauseBeforeTask = pauseBeforeTask;

% must be numeric
cpDotsTask.subject = num2str(regexprep(subject_code,'[^0-9]',''));  

timestamp = extract_timestamp(topNode);
diary([dump_folder, 'session_console_',timestamp,'.log'])

cpDotsTask.date = num2str(regexprep(timestamp,'_',''));  % must be numeric

cpDotsTask.probCP = probCP;

topNode.addChild(cpDotsTask);

topNode.run();



csvfile = ...
    [dump_folder, ...
     'completedReversingDots4AFCtrials_', ...
     timestamp,'.csv'];

task = topNode.children{1};
task.saveTrials(csvfile, 'all');
diary off
end