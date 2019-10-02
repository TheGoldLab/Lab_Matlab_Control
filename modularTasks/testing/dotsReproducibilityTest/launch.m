function launch()
% Run the debug version of the Reversing Dots task
topNode = topsTreeNodeTopNode('oneCP');

topNode.addHelpers('screenEnsemble',  ...
   'displayIndex',      0, ...
   'remoteDrawing',     false, ...
   'topNode',           topNode);

topNode.addReadable('dotsReadableHIDKeyboard');

pauseBeforeTask = -1; % -1 means wait for keypress -- see topsTreeNode.pauseBeforeTask

cpDots1Task = topsTreeNodeTaskReversingDotsDebug('cpDots1');
cpDots1Task.taskID = 1;
cpDots1Task.independentVariables='trials.csv'; 
cpDots1Task.trialIterationMethod='sequential';
cpDots1Task.pauseBeforeTask = pauseBeforeTask;
topNode.addChild(cpDots1Task);

topNode.run();

csvfile = 'debugFIRAtable.csv';
topNode.children{1}.saveTrials(csvfile, 'all');
