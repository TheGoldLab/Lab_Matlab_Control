% Script to run a topsTreeeNodeTaskSimpleBanditNoGraphics task
%
% Puts a data file in:
%  <default data path>/simpleBandit/raw/<YEAR_MONTH_DAY_MINUTES_SEC>
% 
% Where
%  <default data path> is defined in dotsTheMachineConfiguration, which
%  reads a config file and looks for the line:
%      <dataPath>['THE PATH']</dataPath>
%
%
% 6/10/19 created by jig

% Make a topNode, which is what sets up the data file
topNode = topsTreeNodeTopNode('simpleBandit');

% Make the task 
task = topsTreeNodeTaskSimpleBanditNoGraphics;

% Add the task to the top node
topNode.addChild(task);

% Run it!
topNode.run();
