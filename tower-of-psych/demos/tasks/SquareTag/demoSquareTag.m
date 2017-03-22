% Demonstrate the SquareTag task, without user input.
% @param logic SquareTagLogic object, the "back end" of SquareTag
% @param av SquareTagAV object, the audio-visual "front end" of SquareTag
% @param tagSteps number of frames to tag each square programmatically
% @details
% demoSquareTag() runs through the SquareTag demo task without user
% intervention.  It coordinates the behaviors of the given @a logic and @a
% av objects to make a complete task-like demo.  If @a logic or @a
% av is omitted, demoSquareTag() creates a default object.  Instead of
% accepting inputs from a user or subject, demoSquareTag() moves the
% subject's cursor programmatically, over the given @a tagSteps number of
% animation frames.
%
% @ingroup topsDemos
function demoSquareTag(logic, av, tagSteps)

if nargin < 1 || isempty(logic)
    % create a logical "back end" of the SquareTag task
    logic = SquareTagLogic('SquareTag demo', now());
    logic.nTrials = 3;
    logic.nSquares = 5;
end

if nargin < 2 || isempty(av)
    % chose a default audio-visual "front end" to for the task
    av = SquareTagAVPlotter(logic);
end

if nargin < 3 || isempty(tagSteps)
    % choose how long it takes the computer to tag each square
    tagSteps = 10;
end

% start playing SquareTag!
logic.startSession();
av.initialize();
for ii = 1:logic.nTrials
    
    % initialize the logic and av objects for each trial
    logic.startTrial();
    av.doBeforeSquares();
    
    % proceed through squares, one at a time
    while strcmp(logic.nextSquare(), logic.nextOutput)
        
        % indicate which squares are already tagged
        av.doNextSquare();
        
        % peek at the location of the current square
        %   plan programmatic movement towards it
        squarePos = logic.squarePositions(logic.currentSquare, :);
        cursorTarget = squarePos(1:2) + squarePos(3:4)/2;
        cursorGap = cursorTarget - logic.getCursorLocation();
        cursorDelta = cursorGap / tagSteps;
        
        % wait for the next square to be tagged
        %   logic.cursorMap maps cursor location onto squares
        %   and knows which square should be tagged next
        while ~strcmp(logic.cursorMap.getOutput(), logic.tagOutput)
            % programmatically step the cursor towards the next square
            cursorPos = logic.getCursorLocation() + cursorDelta;
            logic.setCursorLocation(cursorPos);
            
            % let the av object draw a new cursor location
            av.updateCursor();
            drawnow();
        end
    end
    
    % indicate trial completion and wait for an interval
    av.doAfterSquares();
    pause(0.5);
    
    % account for the completed trial
    logic.finishTrial();
end

% clean up from playing SquareTag!
logic.finishSession();
av.terminate();