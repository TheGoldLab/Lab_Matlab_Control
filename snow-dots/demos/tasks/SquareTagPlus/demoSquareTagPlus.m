% Demonstrate the SquareTagPlus task, without user input.
% @param logic SquareTagLogic object, the "back end" of SquareTag
% @param av SquareTagAV object, the audio-visual "front end" of SquareTag
% @param tagSteps number of frames to tag each square programmatically
% @details
% demoSquareTagPlus() runs through the SquareTagPlus demo task without user
% intervention.  It coordinates the behaviors of the given @a logic and @a
% av objects to make a complete task-like demo.  If @a logic or @a
% av is omitted, demoSquareTagPlus() creates a default object.  Instead of
% accepting inputs from a user or subject, demoSquareTagPlus() moves the
% subject's cursor programmatically, over the given @a tagSteps number of
% animation frames.
%
% @ingroup dotsDemos
function demoSquareTagPlus(logic, av, tagSteps)

if nargin < 1 || isempty(logic)
    % create a logical "back end" of the SquareTag task
    logic = SquareTagLogic('SquareTagPlus demo', now());
    logic.nTrials = 3;
    logic.nSquares = 5;
end

if nargin < 2 || isempty(av)
    % chose a default audio-visual "front end" to for the task
    av = SquareTagAVPlus(logic);
end

if nargin < 3 || isempty(tagSteps)
    % choose how long it takes the computer to tag each square
    tagSteps = 30;
end

% reuse the Tower of Psych demoSquareTag with these different defaults.
demoSquareTag(logic, av, tagSteps);