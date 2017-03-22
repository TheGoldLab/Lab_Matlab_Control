% Configure the "Spots" task, using only built-in Matlab functionality.
% @param figurePosition optional [x y w h] where to show the task
% @details
% The "Spots" task is a demo for the Tower of Psych.  It uses some tops
% foundataion classes to implement a task similar to a real psychophysics
% task.  The task uses only built-in Matlab functionality, so it can run
% without special installations or configuration.
% @details
% There are two trial types: reaction time (RT) and fixed viewing time
% (FVT).  In both, the subject (you) uses the mouse to click on one of
% several spots that appear.
% @details
% RT trials go like this:
%	-several blue spots and one red spot appear in the figure.
%	-at any time, the subject may click on one of the spots.  The red
%	spot is "correct" and the rest "incorrect".
%	-the spots disappear and the figure is blank for an interval
%	-the next trial begins...
%   .
% @details
% FVT trials go like this:
%	-several blue and one red spot appear in the figure, then quickly
%	all turn black
%	-after the spots are black, the subject may click on one of the
%	spots.  The spot that was red is "correct", the rest "incorrect".
%	-the spots disappear and the figure is blank for an interval.
%	-the next trial begins.
%   .
% @details
% Returns a topsTreeNode object which organizes tasks and trials.
% the object's run() method will start the "Spots" demo task.  Also returns
% as a second argument a topsGroupedList object which holds all the data
% needed for the tasl.
% @details
% Several task parameters may be controlled by editing values near the top
% of configureSpotsTask.m.
%
% @ingroup topsDemos
function [tree, list] = configureSpotsTask(figurePosition)
% 2009 benjamin.heasly@gmail.com
%   Seattle, WA

if ~nargin
    figurePosition = [];
end


%%%
%%% task parameters to edit:
%%%
spotRows = 5;
spotColumns = 5;
spotCount = 6;
spotViewingTime = .25;

intertrialInterval = 1;
trialsInARow = 10;

taskRepetitions = 2;
taskOrder = 'random'; % 'sequential' or 'random'


%%%
%%% foundataion classes
%%%

% topsGroupedList
% list list will hold all parameters and other data for the spots
list = topsGroupedList();
list.addItemToGroupWithMnemonic(figurePosition, 'spots', 'figurePosition');
list.addItemToGroupWithMnemonic(spotRows, 'spots', 'spotRows');
list.addItemToGroupWithMnemonic(spotColumns, 'spots', 'spotColumns');
list.addItemToGroupWithMnemonic(spotCount, 'spots', 'spotCount');
list.addItemToGroupWithMnemonic(spotViewingTime, 'spots', 'spotViewingTime');
list.addItemToGroupWithMnemonic(intertrialInterval, 'spots', 'intertrialInterval');
list.addItemToGroupWithMnemonic(trialsInARow, 'spots', 'trialsInARow');
list.addItemToGroupWithMnemonic(taskRepetitions, 'spots', 'taskRepetitions');
list.addItemToGroupWithMnemonic(taskOrder, 'spots', 'taskOrder');

% topsCallList
% spotsCalls can hold function calls, with arguments, that can be
% called as a batch.  spotsCalls just needs to call drawnow()
spotsCalls = topsCallList();
spotsCalls.addCall({@drawnow}, 'update');
list.addItemToGroupWithMnemonic(spotsCalls, 'spots', 'spotsCalls');

% topsTreeNode
% tree manages the main figure window
%   it also will have the RT and FVT tasks as its "children"
tree = topsTreeNode();
tree.name = 'spots';
tree.iterations = taskRepetitions;
tree.iterationMethod = taskOrder;
tree.startFevalable = {@spotsSetup, list, 'spots'};
tree.finishFevalable = {@spotsTearDown, list, 'spots'};
list.addItemToGroupWithMnemonic(tree, 'spots', 'spotsTopLevel');

% rtTask manages the reaction time task
%   it will also have a reaction time *trial* as its child
rtTask = tree.newChildNode;
taskName = 'rt_task';
rtTask.name = taskName;
rtTask.iterations = trialsInARow;
rtTask.startFevalable = {@rtTaskSetup, list, taskName};
rtTask.finishFevalable = {@rtTaskTearDown, list, taskName};
list.addItemToGroupWithMnemonic(rtTask, taskName, 'rtTask');

% rtTrial manages individual reaction time trials
rtTrial = rtTask.newChildNode;
rtTrial.name = 'rt_trial';
rtTrial.startFevalable = {@rtTrialSetup, list, taskName};
rtTrial.addChild(spotsCalls);
rtTrial.finishFevalable = {@rtTrialTeardown, list, taskName};
list.addItemToGroupWithMnemonic(rtTrial, taskName, 'rtTrial');

% fvtTask manages the fixed viewing time task
%   it will also have a fixed viewing time time *trial* as its child
fvtTask = tree.newChildNode;
taskName = 'fvt_task';
fvtTask.name = taskName;
fvtTask.iterations = trialsInARow;
fvtTask.startFevalable = {@fvtTaskSetup, list, taskName};
fvtTask.finishFevalable = {@fvtTaskTearDown, list, taskName};
list.addItemToGroupWithMnemonic(fvtTask, taskName, 'fvtTask');

% another bottom level node, to manage a fixed viewing time trial
fvtTrial = fvtTask.newChildNode;
fvtTrial.name = 'fvt_trial';
fvtTrial.startFevalable = {@fvtTrialSetup, list, taskName};
fvtTrial.addChild(spotsCalls);
fvtTrial.finishFevalable = {@fvtTrialTeardown, list, taskName};
list.addItemToGroupWithMnemonic(fvtTrial, taskName, 'fvtTrial');


%%%
%%% Functions for the overall task (the top level)
%%%
function spotsSetup(list, modeName)
fp = list.getItemFromGroupWithMnemonic(modeName, 'figurePosition');
fig = figure( ...
    'Name', 'See Spots', ...
    'Units', 'normalized', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
if ~isempty(fp)
    set(fig, 'Position', fp);
end
list.addItemToGroupWithMnemonic(fig, modeName, 'figure');

ax = axes('Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [.01 .01 .98 .98], ...
    'XLim', [-1 1], ...
    'YLim', [-1 1], ...
    'XTick', [], ...
    'YTick', [], ...
    'Box', 'on');
list.addItemToGroupWithMnemonic(ax, modeName, 'axes');

function spotsTearDown(list, modeName)
fig = list.getItemFromGroupWithMnemonic(modeName, 'figure');
close(fig);

function waitForUserClick(list, message)
fig = list.getItemFromGroupWithMnemonic('spots', 'figure');
button = uicontrol( ...
    'Parent', fig, ...
    'Style', 'togglebutton', ...
    'Value', false, ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1], ...
    'String', message);
while get(button, 'Value') == false
    drawnow;
end
delete(button);
drawnow();


%%%
%%% Functions for the RT task (a middle level)
%%%
function rtTaskSetup(list, modeName)
% build stimulus spots in the axes
ax = list.getItemFromGroupWithMnemonic('spots', 'axes');
n = list.getItemFromGroupWithMnemonic('spots', 'spotCount');
r = list.getItemFromGroupWithMnemonic('spots', 'spotRows');
c = list.getItemFromGroupWithMnemonic('spots', 'spotColumns');
shuffle = randperm(r*c);
area = [-1 -1 2 2];
for ii = 1:n
    m = shuffle(ii);
    pos = subposition(area, r, c, mod(m,c)+1, ceil(m/c));
    topsDataLog.logDataInGroup(pos, 'made new spot');
    spots(ii) = rectangle('Parent', ax, ...
        'Position', pos,...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'Visible', 'off');
end
list.addItemToGroupWithMnemonic(spots, modeName, 'spots');

msg = 'Click the red spot--as soon as you can.';
waitForUserClick(list, msg);


function rtTaskTearDown(list, modeName)
spots = list.getItemFromGroupWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the RT trial (a bottom level)
%%%
function rtTrialSetup(list, modeName)
spotsCalls = list.getItemFromGroupWithMnemonic('spots', 'spotsCalls');
spots = list.getItemFromGroupWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@rtTrialSpotCallback, spotsCalls, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on');
drawnow;

function rtTrialSpotCallback(spot, event, spotsCalls, redSpot)
topsDataLog.logDataInGroup(get(spot, 'Position'), 'picked spot');
if spot==redSpot
    topsDataLog.logDataInGroup([], 'correct');
else
    topsDataLog.logDataInGroup([], 'incorrect');
end
spotsCalls.isRunning = false;

function rtTrialTeardown(list, modeName)
spots = list.getItemFromGroupWithMnemonic(modeName, 'spots');
iti = list.getItemFromGroupWithMnemonic('spots', 'intertrialInterval');
set(spots, 'Visible', 'off');
pause(iti);


%%%
%%% Functions for the fixed viewing time task
%%%
function fvtTaskSetup(list, modeName)
% build stimulus spots in the axes
ax = list.getItemFromGroupWithMnemonic('spots', 'axes');
n = list.getItemFromGroupWithMnemonic('spots', 'spotCount');
r = list.getItemFromGroupWithMnemonic('spots', 'spotRows');
c = list.getItemFromGroupWithMnemonic('spots', 'spotColumns');
shuffle = randperm(r*c);
area = [-1 -1 2 2];
for ii = 1:n
    m = shuffle(ii);
    pos = subposition(area, r, c, mod(m,c)+1, ceil(m/c));
    topsDataLog.logDataInGroup(pos, 'made new spot');
    spots(ii) = rectangle('Parent', ax, ...
        'Position', pos,...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'LineStyle', ':', ...
        'LineWidth', 2, ...
        'Visible', 'off');
end
list.addItemToGroupWithMnemonic(spots, modeName, 'spots');

msg = 'Click the red spot--after it turns black.';
waitForUserClick(list, msg);

function fvtTaskTearDown(list, modeName)
spots = list.getItemFromGroupWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the fixed viewing time trial
%%%
function fvtTrialSetup(list, modeName)
spotsCalls = list.getItemFromGroupWithMnemonic('spots', 'spotsCalls');
vt = list.getItemFromGroupWithMnemonic('spots', 'spotViewingTime');

spots = list.getItemFromGroupWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@fvtTrialSpotCallback, spotsCalls, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on', 'HitTest', 'off');
pause(vt);
set(spots, 'FaceColor', [0 0 0], 'HitTest', 'on');
drawnow;

function fvtTrialSpotCallback(spot, event, spotsCalls, redSpot)
topsDataLog.logDataInGroup(get(spot, 'Position'), 'picked spot');
if spot==redSpot
    topsDataLog.logDataInGroup([], 'correct');
else
    topsDataLog.logDataInGroup([], 'incorrect');
end
spotsCalls.isRunning = false;

function fvtTrialTeardown(list, modeName)
spots = list.getItemFromGroupWithMnemonic(modeName, 'spots');
iti = list.getItemFromGroupWithMnemonic('spots', 'intertrialInterval');
set(spots, 'Visible', 'off');
pause(iti);