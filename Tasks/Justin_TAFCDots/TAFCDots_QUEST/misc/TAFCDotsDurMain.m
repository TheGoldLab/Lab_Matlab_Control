function [tree, list] = TAFCDotsDurMain()
% Configure the Helicopter version of the 2011 predictive inference task.
% JTM's version for fMRI
% Revised by TDK, 07/06/2012
% For the within trial change-point

% clear classes
% path to task svn repository (latest version) and local subfunctions
addpath(genpath(fullfile('..','taskCode','goldLab','TAFCDots')));

% subject ID info
[dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo('TAFCDotsDur');

topsDataLog.flushAllData();

% initializing
disp('--INITIALIZING--');
time = clock;
randSeed = time(6)*10e6;
logic = TAFCDotsLogic(randSeed);
logic.name = 'TAFC Reaction Time Perceptual Task';
logic.dataFileName = dataFileName;
% logic.dataFileName = 'dummydata';
logic.time = time;
isClient = input('boolean isClient = ');
logic.nBlocks = input('number of blocks = ');
logic.trialsPerBlock = input('trials per block = ');
logic.catchTrialProbability = input('catch trial probability = ');
logic.rel = input('coherence = ');

[tree, list] = configureTAFCDotsDur(logic, isClient);

% visualize the task's structure
% tree.gui();
% list.gui();

%% execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();

%topsDataLog.gui();