% Demonstrate the Dotris game, without user input.
% @param logic DotrisLogic object, the "back end" of Dotris
% @param av DotrisAV object, the audio-visual "front end" of Dotris
% @details
% demoDotrisPlus() runs through the Dotris demo task without user
% intervention.  It coordinates the behaviors of the given @a logic and @a
% av objects to make a complete task-like demo.  If @a logic or @a
% av is omitted, demoDotris() creates a default object.  Instead of
% accepting inputs from a user or subject, demoDotris() moves the
% subject's cursor programmatically, over the given @a tagSteps number of
% animation frames.
%
% @ingroup dotsDemos
function demoDotris(logic, av, tagSteps)

if nargin < 1 || isempty(logic)
    % create a logical "back end" of the Dotris task
    logic = DotrisLogic('Dotris demo');
end

if nargin < 2 || isempty(av)
    % chose a default audio-visual "front end" to for the task
    av = DotrisAVPueblo(logic);
end

% Start the game
logic.startDotris();
av.initialize();

% Move around and "play" a bit
while strcmp(logic.judge(), logic.outputContinue)
    
    % move until the piece ratchets all the way down to the pile
    while strcmp(logic.ratchet(), logic.outputRatchetOK)
        av.updateEverything();
        
        % choose a behavior at random
        choice = 1 + floor(rand()*5);
        switch choice
            case 1
                logic.slidePiece(1);
                logic.slidePiece(1);
                
            case 2
                logic.slidePiece(-1);
                logic.slidePiece(-1);
                
            case 3
                logic.spinPiece(1);
                
            case 4
                logic.spinPiece(-1);
                
            case 5
                logic.dropPiece();
        end
        
        pause(0.25);
    end
    
    % the piece hit the pile
    logic.landPiece();
    logic.newPiece();
end

% show the failure state of the game
pause(0.25);

% Finish the game
av.terminate();