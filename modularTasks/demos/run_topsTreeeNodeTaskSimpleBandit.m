% Script to run a topsTreeeNodeTaskSimpleBandit task
%
% 6/8/19 created by jig

%% SET UP THE TOPS TREE NODE OBJECT

% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode and give it a name
topNode = topsTreeNodeTopNode('simpleBandit');

% ---- Add a topsGroupedList as nodeData to the topsTreeNodeTopNode
%
% nodeData is a property of a topsTreeNode that can be used any way you
%  want. Here we set it up as a topsGroupedList, which is just a convenient 
%  way to store property/value "settings" we use to control task behaviors.
%  By putting them here, as long as you have access to the topNode you 
%  can then always access these properties.
settings = { ...
   'trialIterations',      3, ... % repeats of each trial type
   'readable',             'dotsReadableHIDKeyboard', ...
   'runGUIname',           'eyeGUI',   ... % use standard run gui
   'databaseGUIname',      [],         ... % no database gui (for now)
   'instructionDuration',  3.0,        ...
   'remoteDrawing',        true, ...
   'displayIndex',         1}; % 0=small, 1=main
topNode.nodeData = topsGroupedList.createGroupFromList('Settings', settings);

% ---- Add GUIS
%
% The first is the "run gui" that has some buttons to start/stop
%  running and some real-time output of eye position. The "database gui" is
%  a series of dialogs that execute at the beginning to collect subject/task
%  information and store it in a standard format.
topNode.addGUIs( ...
   'run',                  topNode.nodeData{'Settings'}{'runGUIname'}, ...
   'database',             topNode.nodeData{'Settings'}{'databaseGUIname'});

% ---- Add the screen ensemble as a "helper" object. 
%
%  See topsTaskHelperScreenEnsemble for details
topNode.addHelpers('screenEnsemble',  ...
   'displayIndex',         topNode.nodeData{'Settings'}{'displayIndex'}, ...
   'remoteDrawing',        topNode.nodeData{'Settings'}{'remoteDrawing'}, ...
   'topNode',              topNode);

% ---- Add a readable helper object. 
%
% See topsTreeNodeTopNode.addReadable for other optional parameters
topNode.addReadable(topNode.nodeData{'Settings'}{'readables'});

%% MAKE AND ADD THE TASK

% ---- Make the task
%
task = topsTreeNodeTaskSimpleBandit();

% ---- Set properties
%
% taskID and taskTypeID are meant to be scalars that you can use 
%  to uniquely define the taskType (in this case a
%  topsTreeeNodeTaskSimpleBandit) and task configuration. These are useful
%  because they are stored automatically in each trialData struct, which 
%  is a struct of numeric values (which is why these need to be indices and
%  not strings) that is stored to a file each time it is run. Thus, these
%  two ID values can be used to figure out from that struct which task 
%  (i.e., the taskID) and configuration (i.e., the taskTypeID) was used
%  on that trial.
task.taskID          = 1;
task.taskTypeID      = 1;
task.trialIterations = topNode.nodeData{'Settings'}{'trialIterations'};

% ---- Add a welcome message as a message helper
%
%  Make a helper using the message helper class
helper = topsTaskHelper.makeHelpers('message', 'welcomeMessage');

% Add a message. See topsTaskHelperMessage.addGroup for details
helper.addGroup('Welcome', ...
   'text',             {'About to start', 'y', 6'}, ...
   'images',           {'thumbsUp.jpg', 'y', -6}, ...
   'duration',         2.0, ...
   'pauseDuration',    0.5);

% Add it as an fevalable to the task start call list
task.addCall('start', {@show, helper, 'Welcome'});

% ---- Add as child to the topsTreeNode.
%
topNode.addChild(task);

%% RUN THE TASK!

topNode.run();