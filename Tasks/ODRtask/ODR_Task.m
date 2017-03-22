function [tree, list] = ODR_Task(decisiontime_max)
% Kyra Schapiro 2/6/17

% subject ID info
[dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo('WM ODR task');

topsDataLog.flushAllData();

% initializing
disp('--INITIALIZING--');
time = clock;
randSeed = time(6)*10e6;

if nargin==0
    decisiontime_max = Inf;
end

logic = ODRLogic(randSeed);
logic.name = 'TAFC Reaction Time Perceptual Task';
logic.dataFileName = dataFileName;
logic.time = time;
isClient = 0;
logic.nBlocks = 1;      %1 for testing, should be at least 2 late, ODR, ODR with priors: can switch this to fit Kamesh structure
logic.trialsPerBlock = 5;   %Need to switch this, only 5 for testing purposes
%logic.practiceN = input('practice trial # = ');



logic.decisiontime_max = decisiontime_max;

% Experiment paradigm
[tree, list] = configureODRtask(logic, isClient); 


%% Execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();
