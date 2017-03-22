% Play the Encounter game to demonstrate Tower of Psych.
%
% @ingroup topsDemos
function encounter()

% get objects that can run the game
[runnable, list] = configureEncounter();

% view flow structure and data
% runnable.gui();
% list.gui();

% play Encounter!
topsDataLog.flushAllData();
runnable.run();

% view data logged during the task
%topsDataLog.gui();