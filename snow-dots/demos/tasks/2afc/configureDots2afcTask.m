% Configure a dots kinetogram 2-alternative forced choice task.
% @param isClient optional, whether to show graphics remotely(true).
% @details
% Initializes 2-alternative, forced-choice task, using a random dot
% kinetogam and either gamepad or keyboard USB inputs.  By default,
% displays graphics in the local Matlab instance.  If @a isClient is
% provided and true, attempts to display graphics in a remote Matlab
% instance running dotsEnsembleServer.
% @details
% Returns a a topsTreeNode object which organizes tasks and trials.
% the object's run() method will start the task.  The object's gui() method
% will launch a graphical interface for viewing the organization of the
% task.
% @details
% Also returns as a second output a topsGroupedList object which holds all
% the objects and data needed to run the task, including tree.  The list's
% gui() method will launch a graphical interface for viewing the objects
% and data.
% @details
% The task uses graphical stimuli including targets, a fixation point,
% and a random dot kinetogram.  The subject is expected to decide towards
% which target the dots in the kinetogram appeared to be moving.
% @details
% The task uses a HID gamepad to take input.  The subject may choose
% "left" or "right" by holding down the gamepad's x axis in either
% direction.  The subject may indicate a "commitment" by pressing the
% gamepad's primary button.
% @details
% If a HID gamepad is not connected, the task falls back on the keyboard.
% The subject may choose "left" or "right" by holding down the the F or J
% key. The subject may indicate a "commitment" by pressing the space bar.
% @details
% The task defines multiple trial types, each containing one stimulus
% presentation and one decision.  The trials types all follow the same
% general sequence:
%	- the fixation point appears on the blank screen
%	- there is a "prepare" time interval
%	- the dots kinetogram appears on the screen
%	- there is a "stimulus" time interval:
%       - the kinetogram presents a motion signal
%       .
%   - the two gray targets appear on the screne
%   - there is a "choice" time interval:
%       - the subject holds down "left" or "right" to select a target
%       .
%   - there is a short "feedback" interval
%       - the two targets turn green or red, if the subject was correct
%       or incorrect
%       .
%   - the screen goes blank
%   - the trial ends and an intertrial interval follows
%   .
% @details
% Each trial type is a variation on this trial sequence, with specific
% timing behavior.  The three trial types are:
%   - Fixed Time
%       - the "prepare" interval is constant
%       - the "stimulus" interval is constant
%       - the "choice" interval is constant
%       .
%   - Reaction Time
%       - the "prepare" interval is constant
%       - the "stimulus" interval lasts until the subject chooses
%       "left" or "right"
%       - the "choice" interval lasts until the subject indicates
%       "commitment"
%       .
%   - Prepare Time
%       - the "prepare" interval lasts until the subject indicates
%       "commitment"
%       - the "stimulus" interval is constant
%       - the "choice" interval is constant
%       .
%   .
% The "feedback" interval is constant for all trial types.
% @details
% topsDataLog logs stimulus data, subject data, and data about the flow
% of events during the task.  Following a run of the 2afc task, try
% topsDataLog.gui() to view logged task events.
% @details
% Task parameters, such as the lengths of constant time intervals, may be
% edited in the "Constants" section near the top of this file,
% configureDots2afcTask.m.
%
% @ingroup dotsDemos
function [tree, list] = configureDots2afcTask(isClient)

if nargin < 1
    isClient = false;
end

%% Organization:
% Make a container for task data and objects, partitioned into groups.
list = topsGroupedList('2afc data');


%% Constants:
% Store some constants in the list container, for use during configuration
% and while task is running
list{'timing'}{'prepare'} = 1;
list{'timing'}{'stimulus'} = 2;
list{'timing'}{'choice'} = 0.5;
list{'timing'}{'feedback'} = 1;
list{'timing'}{'trial timeout'} = 600;
list{'timing'}{'intertrial'} = 0.5;

list{'graphics'}{'isClient'} = isClient;
list{'graphics'}{'white'} = [1 1 1];
list{'graphics'}{'gray'} = [0.5 0.5 0.5];
list{'graphics'}{'red'} = [0.75 0.25 0.1];
list{'graphics'}{'green'} = [.25 0.75 0.1];
list{'graphics'}{'stimulus diameter'} = 5;
list{'graphics'}{'fixation diameter'} = 0.5;
list{'graphics'}{'target diameter'} = 1;
list{'graphics'}{'cursor diameter'} = 1.5;
list{'graphics'}{'leftward'} = 180;
list{'graphics'}{'rightward'} = 0;
list{'graphics'}{'left side'} = -5;
list{'graphics'}{'right side'} = 5;


%% Graphics:
% Create some drawable objects. Configure them with the constants above.

% a fixation point
fp = dotsDrawableTargets();
fp.colors = list{'graphics'}{'gray'};
fp.width = list{'graphics'}{'fixation diameter'};
fp.height = list{'graphics'}{'fixation diameter'};
list{'graphics'}{'fixation point'} = fp;

% target dots
targs = dotsDrawableTargets();
targs.colors = list{'graphics'}{'gray'};
targs.width = list{'graphics'}{'target diameter'};
targs.height = list{'graphics'}{'target diameter'};
left = list{'graphics'}{'left side'};
right = list{'graphics'}{'right side'};
targs.xCenter = [left, right];
targs.yCenter = [0 0];
targs.isVisible = false;
list{'graphics'}{'targets'} = targs;

% a cursor dot to indicate user selection
cursor = dotsDrawableTargets();
cursor.colors = list{'graphics'}{'gray'};
cursor.width = list{'graphics'}{'cursor diameter'};
cursor.height = list{'graphics'}{'cursor diameter'};
cursor.xCenter = 0;
cursor.yCenter = 0;
cursor.isVisible = false;
list{'graphics'}{'cursor'} = cursor;

% a random dots stimulus
stim = dotsDrawableDotKinetogram();
stim.colors = list{'graphics'}{'white'};
stim.pixelSize = 3;
stim.direction = 0;
stim.diameter = list{'graphics'}{'stimulus diameter'};
stim.isVisible = false;
list{'graphics'}{'stimulus'} = stim;

% aggregate all these drawable objects into a single ensemble
%   if isClient is true, graphics will be drawn remotely
isClient = list{'graphics'}{'isClient'};
drawables = dotsEnsembleUtilities.makeEnsemble('drawables', isClient);
fpInd = drawables.addObject(fp);
targsInd = drawables.addObject(targs);
cursorInd = drawables.addObject(cursor);
stimInd = drawables.addObject(stim);

% automate the task of drawing all these objects
drawables.automateObjectMethod('draw', @mayDrawNow);

% also put dotsTheScreen into its own ensemble
screen = dotsEnsembleUtilities.makeEnsemble('screen', isClient);
screen.addObject(dotsTheScreen.theObject());

% automate the task of flipping screen buffers
screen.automateObjectMethod('flip', @nextFrame);

list{'graphics'}{'drawables'} = drawables;
list{'graphics'}{'fixation point index'} = fpInd;
list{'graphics'}{'targets index'} = targsInd;
list{'graphics'}{'cursor index'} = cursorInd;
list{'graphics'}{'stimulus index'} = stimInd;
list{'graphics'}{'screen'} = screen;


%% Input:
% Create an input source.
% First, try to find a gamepad.  If there's no gamepad, use the keyboard.
gp = dotsReadableHIDGamepad();
if gp.isAvailable
    % use the gamepad
    ui = gp;
    
    % define movements, which must be held down
    %   map x-axis -1 to left and +1 to right
    isX = strcmp({gp.components.name}, 'x');
    xAxis = gp.components(isX);
    uiMap.left.ID = xAxis.ID;
    uiMap.right.ID = xAxis.ID;
    gp.setComponentCalibration(xAxis.ID, [], [], [-1 +1]);
    
    % undefine any default events
    IDs = gp.getComponentIDs();
    for ii = 1:numel(IDs)
        gp.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    %   any non-zero x-axis position is a 'moved' event
    %   pressing the primary button is a 'commit' event
    gp.defineEvent(xAxis.ID, 'moved', 0, 0, true);
    isButtonOne = [gp.components.ID] == gp.buttonIDs(1);
    buttonOne = gp.components(isButtonOne);
    gp.defineEvent(buttonOne.ID, 'commit', buttonOne.CalibrationMax);
    
else
    % fallback on keyboard inputs
    kb = dotsReadableHIDKeyboard();
    ui = kb;
    
    % define movements, which must be held down
    %   map f-key -1 to left and j-key +1 to right
    isF = strcmp({kb.components.name}, 'KeyboardF');
    isJ = strcmp({kb.components.name}, 'KeyboardJ');
    fKey = kb.components(isF);
    jKey = kb.components(isJ);
    uiMap.left.ID = fKey.ID;
    uiMap.right.ID = jKey.ID;
    kb.setComponentCalibration(fKey.ID, [], [], [0 -1]);
    kb.setComponentCalibration(jKey.ID, [], [], [0 +1]);
    
    % undefine any default events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    %   pressing f or j is a 'moved' event
    %   pressing space bar is a 'commit' event
    kb.defineEvent(fKey.ID, 'moved', 0, 0, true);
    kb.defineEvent(jKey.ID, 'moved', 0, 0, true);
    isSpaceBar = strcmp({kb.components.name}, 'KeyboardSpacebar');
    spaceBar = kb.components(isSpaceBar);
    kb.defineEvent(spaceBar.ID, 'commit', spaceBar.CalibrationMax);
    
end
list{'input'}{'controller'} = ui;
list{'input'}{'mapping'} = uiMap;


%% Control:
% Create three types of control objects:
%	- topsTreeNode organizes flow outside of trials
%	- topsConditions organizes parameter combinations before each trial
%	- topsStateMachine organizes flow within trials
%	- topsCallList organizes calls some functions during trials
%	- topsConcurrentComposite interleaves behaviors of the state machine,
%	function calls, and drawing graphics
%   .

% combinations of parameter values to traverse during each trial type
%   and where to set the parameter values before each trial
taskConditions = topsConditions('pick conditions');
taskConditions.addParameter('direction', {0, 180});
taskConditions.addAssignment('direction', stim, '.', 'direction');
taskConditions.setPickingMethod('shuffled', 2);
list{'control'}{'task conditions'} = taskConditions;

% the trunk of the tree, branches are added below
tree = topsTreeNode('2afc task');
tree.iterations = 1;
tree.startFevalable = {@callObjectMethod, screen, @open};
tree.finishFevalable = {@callObjectMethod, screen, @close};

% a batch of function calls that apply to all the trial types below
%   start- and finishFevalable get called once per trial
%   addCall() accepts fevalables to be called repeatedly during a trial
trialCalls = topsCallList('call functions');
trialCalls.addCall({@read, ui}, 'read input');
list{'control'}{'trial calls'} = trialCalls;


%% Fixed Time
% Define states for trials with constant timing.

fixedMachine = topsStateMachine('traverse states');

tPrep = list{'timing'}{'prepare'};
tStim = list{'timing'}{'stimulus'};
tChoice = list{'timing'}{'choice'};
tFeed = list{'timing'}{'feedback'};
tTrial = list{'timing'}{'trial timeout'};

% define shorthand functions for showing and hiding ensemble drawables
on = @(index)drawables.setObjectProperty('isVisible', true, index);
off = @(index)drawables.setObjectProperty('isVisible', false, index);

fixedStates = { ...
    'name'      'entry'         'timeout'	'exit'          'next'; ...
    'prepare'   {on fpInd}      tPrep       {}              'stimulus'; ...
    'stimulus'  {on stimInd}	tStim       {off stimInd}	'choice'; ...
    'choice'    {on targsInd}	tChoice     {}              'feedback'; ...
    'feedback'  {@showFeedback list} tFeed	{}              ''; ...
    };
fixedMachine.addMultipleStates(fixedStates);
fixedMachine.startFevalable = {@startTrial, list};
fixedMachine.finishFevalable = {@finishTrial, list};
list{'control'}{'fixed time machine'} = fixedMachine;

fixedConcurrents = topsConcurrentComposite('run() concurrently:');
fixedConcurrents.addChild(trialCalls);
fixedConcurrents.addChild(fixedMachine);
fixedConcurrents.addChild(drawables);
fixedConcurrents.addChild(screen);

% add a branch to the tree trunk to lauch a Fixed Time trial
fixedTree = tree.newChildNode('fixed time trial');
fixedTree.iterations = inf;
fixedTree.addChild(taskConditions);
fixedTree.addChild(fixedConcurrents);

%% Reaction Time
% Define states for trials with interactive timing.

reactionMachine = topsStateMachine('traverse states');

% only need to modify states from Fixed Time
%   respond to input during stimulus
%   wait for a button press commitment
stimTargInd = [stimInd targsInd];
reactionStates = { ...
    'name'      'entry'         'timeout'	'input'             'exit'          'next'; ...
    'stimulus'	{on stimTargInd} tTrial     {@getNextEvent ui}  {off stimInd}   'feedback'; ...
    'moved'     {}              0           {}                  {}              'choice'; ...
    'choice'    {@showChoice list} tTrial   {@getNextEvent ui}	{}              'feedback'; ...
    'commit'    {}              0           {}                  {}              'feedback'; ...
    };

% start with the same states as the Fixed Time trials
%   add and replace some states for reaction time behavior
reactionMachine.addMultipleStates(fixedStates);
reactionMachine.addMultipleStates(reactionStates);
reactionMachine.startFevalable = {@startTrial, list};
reactionMachine.finishFevalable = {@finishTrial, list};
list{'control'}{'reaction time machine'} = reactionMachine;

reactionConcurrents = topsConcurrentComposite('run() concurrently:');
reactionConcurrents.addChild(trialCalls);
reactionConcurrents.addChild(reactionMachine);
reactionConcurrents.addChild(drawables);
reactionConcurrents.addChild(screen);

% add a branch to the tree trunk to lauch a Fixed Time trial
reactionTree = tree.newChildNode('reaction time trial');
reactionTree.iterations = inf;
reactionTree.addChild(taskConditions);
reactionTree.addChild(reactionConcurrents);


%% Prepare Time
% Define states for trials with an interactive preparation delay.

preparationMachine = topsStateMachine('traverse states');

% only need to modify states from Fixed Time
%   respond to input during prepare
preparationStates = { ...
    'name'      'entry'    'timeout'	'input'             'next'; ...
    'prepare'   {on fpInd} tTrial       {@getNextEvent ui}	'feedback'; ...
    'commit'    {}         0            {}                  'stimulus'; ...
    };

% start with the same states as the Fixed Time trials
%   add and replace some states for prepare time behavior
preparationMachine.addMultipleStates(fixedStates);
preparationMachine.addMultipleStates(preparationStates);
preparationMachine.startFevalable = {@startTrial, list};
preparationMachine.finishFevalable = {@finishTrial, list};
list{'control'}{'prepare time machine'} = preparationMachine;

preparationConcurrents = topsConcurrentComposite('run() concurrently:');
preparationConcurrents.addChild(trialCalls);
preparationConcurrents.addChild(preparationMachine);
preparationConcurrents.addChild(drawables);
preparationConcurrents.addChild(screen);

% add a branch to the tree trunk to lauch a Fixed Time trial
preparationTree = tree.newChildNode('prepare time trial');
preparationTree.iterations = inf;
preparationTree.addChild(taskConditions);
preparationTree.addChild(preparationConcurrents);


%% Custom Behaviors:
% Define functions to handle some of the unique details of this task.

function startTrial(list)
% clear data from the last trial
ui = list{'input'}{'controller'};
ui.flushData();
list{'control'}{'current choice'} = 'none';

% reset the appearance of targets and cursor
%   use the drawables ensemble, to allow remote behavior
drawables = list{'graphics'}{'drawables'};
cursorInd = list{'graphics'}{'cursor index'};
targsInd = list{'graphics'}{'targets index'};
drawables.setObjectProperty( ...
    'colors', list{'graphics'}{'gray'}, [cursorInd, targsInd]);

% let all the graphics set up to draw in the open window
drawables.setObjectProperty('isVisible', false);
drawables.callObjectMethod(@prepareToDrawInWindow);


function finishTrial(list)
% only need to wait our the intertrial interval
pause(list{'timing'}{'intertrial'});


function readChoice(list)
% look for held-down left and right, using uiMap
ui = list{'input'}{'controller'};
uiMap = list{'input'}{'mapping'};
isLeft = ui.getValue(uiMap.left.ID) == -1;
isRight = ui.getValue(uiMap.right.ID) == +1;

if isLeft
    list{'control'}{'current choice'} = 'leftward';
elseif isRight
    list{'control'}{'current choice'} = 'rightward';
end


function showChoice(list)
% update the current choice from the user input
readChoice(list);

% indicate left or right with by moving the cursor over the targets
drawables = list{'graphics'}{'drawables'};
cursorInd = list{'graphics'}{'cursor index'};
choice = list{'control'}{'current choice'};
if strcmp(choice, 'leftward')
    drawables.setObjectProperty( ...
        'xCenter', list{'graphics'}{'left side'}, cursorInd);
    drawables.setObjectProperty('isVisible', true, cursorInd);
    
elseif strcmp(choice, 'rightward')
    drawables.setObjectProperty( ...
        'xCenter', list{'graphics'}{'right side'}, cursorInd);
    drawables.setObjectProperty('isVisible', true, cursorInd);
    
else
    % no choice, hide the cursor
    drawables.setObjectProperty('isVisible', false, cursorInd);
end


function showFeedback(list)
% hide the fixation point and cursor
drawables = list{'graphics'}{'drawables'};
fpInd = list{'graphics'}{'fixation point index'};
cursorInd = list{'graphics'}{'cursor index'};
drawables.setObjectProperty('isVisible', false, [fpInd cursorInd]);

% check which way the dots were really moving
stimInd = list{'graphics'}{'stimulus index'};
stimAngle = drawables.getObjectProperty('direction', stimInd);
if cosd(stimAngle) > 0
    stimDir = 'rightward';
else
    stimDir = 'leftward';
end

% compare stimulus direction to choice direction
readChoice(list);
choiceDir = list{'control'}{'current choice'};
isCorrect = strcmp(stimDir, choiceDir);

% indicate correct or incorrect by coloring in the targets
targsInd = list{'graphics'}{'targets index'};
if isCorrect
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'green'}, targsInd);
else
    drawables.setObjectProperty( ...
        'colors', list{'graphics'}{'red'}, targsInd);
end