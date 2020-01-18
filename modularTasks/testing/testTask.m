function testTask(taskName, noGraphics)
% function testTask(taskName, noGraphics)
%
% Test task with the given name
%
% Arguments:
%  taskName   ... string name, without topsTreeNodeTask suffix
%  noGraphics ... if true, do not use screen

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode('test');

% Add the screen ensemble as a "helper" object. See
% topsTaskHelperScreenEnsemble for details
if nargin < 2 || isempty(noGraphics) || ~noGraphics
   topNode.addHelpers('screenEnsemble',  ...
      'displayIndex',      0, ...
      'remoteDrawing',     false, ...
      'topNode',           topNode);
end

% Add 'dummy' readable that generates random events
topNode.addReadable('dotsReadableDummy');

% Get the task
if ~strncmp('topsTreeNodeTask', taskName, length('topsTreeNodeTask'))
   prefix = 'topsTreeNodeTask';
else
   prefix = '';
end
task = feval([prefix taskName '.getTestConfiguration']);

% Add the task
topNode.addChild(task);

% Run it
topNode.run();

