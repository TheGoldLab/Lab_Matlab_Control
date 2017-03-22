% Play the Dotris game!
clear
close all

% create an audio-visial "front end" for the game
%   isClient = true means send graphics to a remote ensemble server
isClient = false;
av = DotrisAVPueblo(isClient);

% wire up a Dotris game with default logic and given av
[runnable, list] = configureDotris([], av);

% view flow structure and data
% runnable.gui();
% list.gui();

% execute Dotris!
topsDataLog.flushAllData();
runnable.run();

% view data logged during the task
%topsDataLog.gui();