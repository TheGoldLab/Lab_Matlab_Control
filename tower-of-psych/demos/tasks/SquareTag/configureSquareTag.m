% Set up the SquareTag demo task, with user inputs.
% @param logic SquareTagLogic object, the "back end" of SquareTag
% @param av SquareTagAV object, the audio-visual "front end" of SquareTag
% @param getXFunction function that returns x-position, as from a mouse
% @param getYFunction function that returns y-position, as from a mouse
% @details
% SquareTag is a demo game for Tower of Psych.  In it the user moves a
% cursor in order to tag several squares, in order of increasing size.  If
% the user tags squares in the wrong trial, the trial starts over.  Square
% Tag can use default inputs and graphics that use only build-in Matlab
% functionality.  It can also be extended to use advanced functionality.
% @details
% Set up to play SquareTag interactively.  Uses @a logic and @a av as the
% "back end" and "front end" of the task, respectively.  If either is
% omitted, configureSquareTag makes defaults. @a getXFunction and @a
% getYFunction must be functions_handles.  Each funciton should return an
% x- or y-position input by the subject, for example from a mouse or
% joystick.  x- and y-values should be scaled to the unit square, so that
% left and bottom are at 0 and top and right are at 1.
% @details
% Returns a topsRunnable object which can be run() to start playing
% SquareTag.  Also returns as a second output a topsGroupedList which
% contains data and objects related to the SquarTag session, including @a
% logic, @a av, @a getXFunction, and @a getYFunction.
%
% @ingroup topsDemos
function [runnable, list] = configureSquareTag( ...
    logic, av, getXFunction, getYFunction)

if nargin < 1 || isempty(logic)
    % use all defaults for logic
    logic = SquareTagLogic('default SquareTag');
end

if nargin < 2 || isempty(av)
    % use the Matlab-only plot-style graphics
    av = SquareTagAVPlotter(logic);
end

if nargin < 3 || isempty(getXFunction)
    % get mouse position from Matlab's "root" object
    getXFunction = @()getRootCursor('x');
end

if nargin < 4 || isempty(getYFunction)
    % get mouse position from Matlab's "root" object
    getYFunction = @()getRootCursor('y');
end

%% Make a container for all kinds of data.
list = topsGroupedList();
list{'logic'}{'object'} = logic;
list{'av'}{'object'} = av;
list{'input'}{'getXFunction'} = getXFunction;
list{'input'}{'getYFunction'} = getYFunction;

%% Make runnables which can execute the task.
runnable = topsTreeNode('SquareTag session');
runnable.startFevalable = {@startSession, logic};
runnable.finishFevalable = {@finishSession, logic};
list{'runnable'}{'object'} = runnable;

avSetup = runnable.newChildNode('av setup');
avSetup.iterations = logic.nTrials;
avSetup.startFevalable = {@initialize, av};
avSetup.finishFevalable = {@terminate, av};

concurrent = topsConcurrentComposite('concurrently:');
avSetup.addChild(concurrent);

%% Make a list of functions to call continuously.
functionCalls = topsCallList('function calls');
functionCalls.addCall( ...
    {@readCursor, logic, getXFunction, getYFunction}, 'readCursor');
functionCalls.addCall({@updateCursor, av}, 'update');

concurrent.addChild(functionCalls);
list{'runnable'}{'functionCalls'} = functionCalls;

%% Make a state machine which controls trial events.
%   The state machine coordinates logic, av, and user inputs
stateMachine = topsStateMachine('trial events');
stateMachine.startFevalable = {@startTrial, logic};
stateMachine.finishFevalable = {@finishTrial, logic};

% define several states which coordinate logic, av, and input
start.name = 'start';
start.next = 'proceed';
start.entry = {@doBeforeSquares, av};
stateMachine.addState(start);

proceed.name = 'proceed';
proceed.input = {@nextSquare, logic};
stateMachine.addState(proceed);

ready.name = 'ready';
ready.timeout = inf;
ready.classification = logic.cursorMap;
ready.entry = {@doNextSquare, av};
stateMachine.addState(ready);

missed.name = 'missed';
missed.next = 'start';
missed.entry = {@restartTrial, logic};
stateMachine.addState(missed);

tagged.name = 'tagged';
tagged.next = 'proceed';
stateMachine.addState(tagged);

done.name = 'done';
stateMachine.addState(done);

concurrent.addChild(stateMachine);
list{'runnable'}{'stateMachine'} = stateMachine;

%% Pass arbitrary cursor data to the logic object.
function readCursor(logic, getXFunction, getYFunction)
logic.setCursorLocation(feval(getXFunction), 'x');
logic.setCursorLocation(feval(getYFunction), 'y');

%% Default way to read cursor position, from Matlab's "root" object.
function p = getRootCursor(xy)
fullScreen = get(0, 'MonitorPositions');
pixelPoint = get(0, 'PointerLocation');
unitlessPoint = pixelPoint ./ fullScreen(1,[3 4]);
if strcmp(xy, 'x')
    p = unitlessPoint(1);
elseif strcmp(xy, 'y')
    p = unitlessPoint(2);
else
    p = unitlessPoint;
end