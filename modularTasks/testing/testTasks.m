function testTasks()
% function testTasks()
%
% Test tasks in the given list

%% ---- Register tasks here
%
% Note: they need to have a "getTestConfiguration" static method
tasks = { ...
   'topsTreeNodeTaskRTDots', ...
   'topsTreeNodeTaskSaccade', ...
   'topsTreeNodeTaskSimpleBandit', ...
   'topsTreeNodeTaskSimpleBanditNoGraphics', ...
   };

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

% Add 'dummy' readable that generates random events
topNode.addReadable('dotsReadableDummy');

% Add the tasks
for tt = 1:length(tasks)
   task = feval([tasks{tt} '.getTestConfiguration']);
   task.taskID = tt;
   % task.pauseBeforeTask = -1;
   
   % Uncomment this line to test control keyboard
   % task.pauseBeforeTask = -1;
      
   topNode.addChild(task);
end

% Run it
topNode.run();

