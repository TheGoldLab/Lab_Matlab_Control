function [tree, list] = TAFCDotsMainDemo(decisiontime_max)
% Based on Ben Heasley's 2afc demo and Matt Nassar's helicopter task
% TDK 9/20/2013

% path to task svn repository (latest version) and local subfunctions
addpath(genpath(fullfile('..','taskCode','goldLab','TAFCDotsCont')));

% subject ID info
[dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo('TAFCDotsCont');

topsDataLog.flushAllData();

% initializing
disp('--INITIALIZING--');
time = clock;
randSeed = time(6)*10e6;

if nargin==0
    decisiontime_max = Inf;
end

% load(['./TAFCDotsData/TAFCDots_cg1_main_2Hz1.mat'])
% randSeed = statusData(1).randSeed;
% clear statusData;

logic = TAFCDotsLogic(randSeed);
logic.name = 'TAFC Reaction Time Perceptual Task';
logic.dataFileName = dataFileName;
logic.time = time;
isClient = 0;
logic.nBlocks = 1;
logic.trialsPerBlock = 1;
% logic.catchTrialProbability = 0;
logic.H = .1;
logic.coherenceset = 20;
logic.minT = 10;
logic.maxT = 10;
logic.practiceN = 0;
% 
% logic.nBlocks = 1;
% logic.trialsPerBlock = 1;
% logic.catchTrialProbability = 0;
% logic.H = 2;
% logic.coherenceset = 10;
% logic.minT = 10;
% logic.maxT = 10;

logic.decisiontime_max = decisiontime_max;

% Experiment paradigm
[tree, list] = configureTAFCDotsDur(logic, isClient); 
%[tree, list] = configureTAFCDotsCPDetect(logic, isClient);% interrogation
%[tree, list] = configureTAFCDots(logic, isClient); % free-response

% Visualize the task's structure
% tree.gui();
% list.gui();

%% Execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();

%topsDataLog.gui();