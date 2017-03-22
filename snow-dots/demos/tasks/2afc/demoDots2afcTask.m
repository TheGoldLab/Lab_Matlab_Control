% Run the "Dots 2afcTask" demo for Snow Dots.
clear
close all

topsDataLog.flushAllData();

% configure all the objects that make up the 2afc task
isClient = false;
[tree, list] = configureDots2afcTask(isClient);

% visualize the task's structure
% tree.gui();
% list.gui();

%% execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();

%topsDataLog.gui();