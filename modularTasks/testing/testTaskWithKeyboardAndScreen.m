function testTaskWithKeyboardAndScreen(taskName)
% function testTaskWithKeyboardAndScreen(taskName)
%
% Simple way to test a tast with default settings

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode('test');

% Add the screen ensemble as a "helper" object. See
% topsTaskHelperScreenEnsemble for details
topNode.addHelpers('screenEnsemble',  ...
   'displayIndex',      0, ...
   'remoteDrawing',     false, ...
   'topNode',           topNode);

% Add keyboard
topNode.addReadable('dotsReadableHIDKeyboard');

% Add the task
task = eval([taskName '.getTestConfiguration']);
task.taskID = 1;
topNode.addChild(task);

% Run it
topNode.run();

