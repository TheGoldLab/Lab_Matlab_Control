function [tree, list] = TAFCDotsMainDemo()
% Based on Ben Heasley's 2afc demo and Matt Nassar's helicopter task
% TDK 9/20/2013

% path to task svn repository (latest version) and local subfunctions
addpath(genpath(fullfile('..','taskCode','goldLab','TAFCDotsCont')));

% subject ID info
gatherInfo = load('scriptRunValues/gatherinfo.mat');
[dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo(gatherInfo.tag,...
    gatherInfo.id, gatherInfo.session, gatherInfo.foldername);

topsDataLog.flushAllData();

% initializing
disp('--INITIALIZING--');
time = clock;
randSeed = time(6)*10e6;

logic_values = load('scriptRunValues/logic_values.mat');

logic = TAFCDotsLogic(randSeed);
logic.name = logic_values.name;
logic.dataFileName = dataFileName;
logic.time = time;
logic.nBlocks = logic_values.nBlocks;
logic.trialsPerBlock = logic_values.trialsPerBlock;
% logic.catchTrialProbability = 0;
logic.H = logic_values.H;
%logic.coherenceset = logic_values.coherenceset;
logic.coherence = logic_values.coherence;
%logic.minT = logic_values.minT;
%logic.maxT = logic_values.maxT;
logic.duration = logic_values.duration;
logic.practiceN = logic_values.practiceN;

decisiontime_value = load('scriptRunValues/DT.mat');
logic.decisiontime_max = decisiontime_value.decisiontime_max;
which_quest = decisiontime_value.which_quest;

isClient_value = load('scriptRunValues/isClient.mat');
isClient = isClient_value.isClient;

% Experiment paradigm
if (which_quest == 3)
    [tree, list] = configureTAFCDotsDur_QUEST_PLUS(logic, isClient);
elseif (which_quest == 2)
    [tree, list] = configureTAFCDotsDur_QUEST_Justin(logic, isClient);
elseif (which_quest ==1)
    [tree, list] = configureTAFCDotsDur(logic, isClient); 
end

%% Execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();
mglClose();