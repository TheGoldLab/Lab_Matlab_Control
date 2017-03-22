% Set up the Dotris demo game, with user inputs.
% @param logic DotrisLogic object, the "back end" of Dotris
% @param av DotrisAV object, the audio-visual "front end" of Dotris
% @details
% Set up to play Dotris interactively.  Uses @a logic and @a av as the
% "back end" and "front end" of the game, respectively.  If either is
% omitted, configureDotris() makes defaults.
% @details
% Returns a topsRunnable object which can be run() to start playing
% Dotris.  Also returns as a second output a topsGroupedList which
% contains data and objects related to the Dotris game, including @a
% logic and @a av.
%
% @ingroup dotsDemos
function [runnable, list] = configureDotris(logic, av)

if nargin < 1 || isempty(logic)
    % use all defaults for logic
    logic = DotrisLogic('Dotris logic');
end

if nargin < 2 || isempty(av)
    % use handsome OpenGL graphics
    av = DotrisAVPueblo();
end
av.logic = logic;

%% Make a container for all kinds of data.
list = topsGroupedList();
list{'logic'}{'object'} = logic;
list{'av'}{'object'} = av;

%% Make a readable which can check user inputs
%% Input:
% Create an input source.
% First, try to find a gamepad.  If there's no gamepad, use the keyboard.
gp = dotsReadableHIDGamepad();
if gp.isAvailable
    % use the gamepad
    ui = gp;
    
    % define left and right movements, which can be held down
    %   map x-axis -1 to left and +1 to right
    uiMap.left.ID = gp.xID;
    uiMap.right.ID = gp.xID;
    gp.setComponentCalibration(gp.xID, [], [], [-1 +1]);
    
    % undefine any default events
    IDs = gp.getComponentIDs();
    for ii = 1:numel(IDs)
        gp.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    
    % any non-zero x-axis position is a 'move' event
    gp.defineEvent(xAxis.ID, 'move', 0, 0, true);
    
    % pressing button 1 is a 'rotate' event
    % pressing button 2 is a 'drop' event
    % pressing button 3 is a 'pause' event
    % pressing button 4 is a 'quit' event
    buttonEvents = {'rotate', 'drop', 'pause', 'quit'};
    nEvents = min(numel(buttonEvents), numel(gp.buttonIDs));
    for ii = 1:nEvents
        isButton = [gp.components.ID] == gp.buttonIDs(ii);
        button = gp.components(isButton);
        gp.defineEvent(button.ID, buttonEvents{ii}, button.CalibrationMax);
    end
    
else
    % fallback on keyboard
    kb = dotsReadableHIDKeyboard();
    ui = kb;
    
    % define left and right movements, which can be held down
    %   map left arrow -1 to left and right arrow +1 to right
    isLeft = strcmp({kb.components.name}, 'KeyboardLeftArrow');
    isRight = strcmp({kb.components.name}, 'KeyboardRightArrow');
    uiMap.left.ID = kb.components(isLeft).ID;
    uiMap.right.ID = kb.components(isRight).ID;
    kb.setComponentCalibration(uiMap.left.ID, [], [], [0 -1]);
    kb.setComponentCalibration(uiMap.right.ID, [], [], [0 +1]);
    
    % undefine any default events
    IDs = kb.getComponentIDs();
    for ii = 1:numel(IDs)
        kb.undefineEvent(IDs(ii));
    end
    
    % define events, which fire once even if held down
    
    % any non-zero left or right value is a 'move' event
    kb.defineEvent(uiMap.left.ID, 'move', 0, 0, true);
    kb.defineEvent(uiMap.right.ID, 'move', 0, 0, true);
    
    % pressing up is a 'rotate' event
    % pressing down is a 'drop' event
    % pressing p is a 'pause' event
    % pressing q is a 'quit' event
    keyEvents = {'rotate', 'drop', 'pause', 'quit'};
    keyNames = ...
        {'KeyboardUpArrow', 'KeyboardDownArrow', 'KeyboardP', 'KeyboardQ'};
    for ii = 1:numel(keyEvents)
        isKey = strcmp({kb.components.name}, keyNames{ii});
        key = kb.components(isKey);
        kb.defineEvent(key.ID, keyEvents{ii}, key.CalibrationMax);
    end
end

% let the ui object update itself on demand, automatically
ui.isAutoRead = true;

list{'input'}{'controller'} = ui;
list{'input'}{'mapping'} = uiMap;
list{'input'}{'repeatInterval'} = 0.2;
list{'input'}{'lastMoveTime'} = 0;

%% Make runnables which can execute the game.
runnable = topsTreeNode('Dotris!');
runnable.startFevalable = {@startDotris, logic};
list{'runnable'}{'top level'} = runnable;

avSetup = runnable.newChildNode('av setup');
avSetup.startFevalable = {@initialize, av};
avSetup.finishFevalable = {@terminate, av};
list{'runnable'}{'av setup'} = avSetup;

%% Make a state machine which controls game events.
%   The state machine coordinates logic, av, and user inputs
stateMachine = topsStateMachine('Dotris events');
avSetup.addChild(stateMachine);
list{'runnable'}{'state machine'} = stateMachine;

% define several states which coordinate logic, av, and input
ready.name = 'ready';
ready.entry = {@scoreToGameSpeed, logic, stateMachine};
ready.input = {@checkGameInput, list, ui, logic, av};
ready.timeout = 1;
ready.next = 'fallDown';
stateMachine.addState(ready);

pause.name = 'pause';
pause.entry = {@doPause, av};
pause.input = {@checkPauseInput, ui};
pause.exit = {@doUnpause, av};
pause.timeout = inf;
stateMachine.addState(pause);

fallDown.name = 'fallDown';
logic.outputRatchetLanded = 'land';
logic.outputRatchetOK = 'ready';
fallDown.input = {@ratchet, logic};
fallDown.exit = {@updateEverything, av};
stateMachine.addState(fallDown);

land.name = 'land';
land.entry = {@landPiece, logic};
land.exit = {@updateEverything, av};
land.next = 'gameStatus';
stateMachine.addState(land);

gameStatus.name = 'gameStatus';
logic.outputGameOver = 'gameOver';
logic.outputContinue = 'nextPiece';
gameStatus.input = {@judge, logic};
gameStatus.exit = {@updateEverything, av};
stateMachine.addState(gameStatus);

gameOver.name = 'gameOver';
stateMachine.addState(gameOver);

nextPiece.name = 'nextPiece';
nextPiece.entry = {@newPiece, logic};
nextPiece.exit = {@updateEverything, av};
nextPiece.next = 'ready';
stateMachine.addState(nextPiece);

quit.name = 'quit';
stateMachine.addState(quit);

%% Update the game speed based on the current score.
function scoreToGameSpeed(logic, stateMachine)
readyTime = max(0, 1 - (logic.score/100));
stateMachine.editStateByName('ready', 'timeout', readyTime);

%% Check user input during game play.
function result = checkGameInput(list, ui, logic, av)
result = '';

% process one next input event
[eventName, data] = ui.getNextEvent();
switch eventName
    case 'move'
        % data contians [ID, value, timestamp]
        %   value is -1 or 1 for left or right
        logic.slidePiece(data(2));
        list{'input'}{'lastMoveTime'} = data(3);
        av.updateEverything();
        
    case 'rotate'
        % spin can be -1 or 1, for left or right
        logic.spinPiece(1);
        av.updateEverything();

    case 'drop'
        % drop the piece all the way down
        %   the last result will be 'land', to land the dropped piece
        result = logic.ratchet();
        while strcmp(result, logic.outputRatchetOK)
            result = logic.ratchet();
        end
        av.updateEverything();
        
    case 'quit'
        result = eventName;
        
    case 'pause'
        result = eventName;
end

% check for held-down 'move' event
[lastName, lastID, names, IDs] = ui.getHappeningEvent();
isMove = strcmp(names, 'move');
if any(isMove)
    % was 'move' held down long enough to repeat?
    elapsed = ui.currentTime() - list{'input'}{'lastMoveTime'};
    interval = list{'input'}{'repeatInterval'};
    if elapsed >= interval
        
        % data contians [ID, value, timestamp]
        %   value is -1 or 1 for left or right
        data = ui.state(IDs(isMove),:);
        logic.slidePiece(data(2));
        list{'input'}{'lastMoveTime'} = ui.currentTime();
        av.updateEverything();
    end
end

% let Matlab relax a little
pause(0.01);


%% Check user input while paused.
function result = checkPauseInput(ui)
% report 'ready' when the user presses pause again
if strcmp(ui.getNextEvent(), 'pause')
    result = 'ready';
else
    result = '';
end

% let Matlab relax a little
pause(0.01);