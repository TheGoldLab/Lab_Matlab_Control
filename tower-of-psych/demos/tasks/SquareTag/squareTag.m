% Play the SquareTag task with built-in Matlab graphics and inputs.
%
% @ingroup topsDemos
function squareTag()

% make a new "back end" for SquareTag
logic = SquareTagLogic('SquareTag demo');
logic.nTrials = 3;
logic.nSquares = 5;

% make a "front end" which defines graphics or sound for the back end
av = SquareTagAVPlotter(logic);

% wire up the back end, front end, and user input
[runnable, list] = configureSquareTag(logic, av);

% view flow structure and data
% runnable.gui();
% list.gui();

% execute SquareTag!
topsDataLog.flushAllData();
runnable.run();

% view data logged during the task
%topsDataLog.gui();