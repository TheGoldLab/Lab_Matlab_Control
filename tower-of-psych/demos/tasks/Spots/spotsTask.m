%Run the "Spots Task" demo for Tower of Psych.
%
% @ingroup topsDemos
function spotsTask()

% manage screen real estate for the task and two tops GUIs
x = .46;
y = .46;
w = .4;
h = .4;
taskPosition = [0 y w h];
treeGUIPosition = [0 0 w h];
logGUIPosition = [x 0 w 2*h];

% configure the Spots Task
[tree, list] = configureSpotsTask(taskPosition);

% launch the treeNodeGUI
g = tree.gui();
set(g.fig, ...
    'Units', 'normalized', ...
    'Position', treeGUIPosition);

% launch the dataLogGUI
topsDataLog.flushAllData();
g = topsDataLog.gui();
set(g.fig, ...
    'Units', 'normalized', ...
    'Position', logGUIPosition);