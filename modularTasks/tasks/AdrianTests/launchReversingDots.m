function launchReversingDots()
% function to launch Reversing Dots task while I am designing it  -- aer

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
topNode.addChild(cpDotsTask);

topNode.run();

timestamp = extract_timestamp(topNode);

csvfile = ...
    ['/Users/adrian/Documents/MATLAB/toolboxes/Lab_Matlab_Control/', ...
     'modularTasks/tasks/AdrianTests/', ...
     'completedReversingDots4AFCtrials_', ...
     timestamp,'.csv'];

task = topNode.children{1};
task.saveTrials(csvfile, 'all');
