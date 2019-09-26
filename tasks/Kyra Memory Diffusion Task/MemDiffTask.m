function [tree, list] = MemDiffTask(decisiontime_max)
% Kyra Schapiro 2/6/17

% subject ID info
[dataFileName, taskPhase, id] = gatherTAFCDotsSubInfo('MemDiffTask');

topsDataLog.flushAllData();

% initializing
disp('--INITIALIZING--');
time = clock;
randSeed = time(6)*10e6;

if nargin==0
    decisiontime_max = Inf;
end

logic = MemLogic(randSeed);
logic.name = 'Mem_Task';
logic.dataFileName = dataFileName;
logic.time = time;
isClient = 0;
logic.nBlocks = 1;      



        logic.trialsPerBlock= 1500 ;




logic.isDemo=input('Demo?: 1=demo, 2=normaltask ');
% logic.totalDelay=input('Total delay length   ');
logic.exptType=input('Objective? 1=Mem, 2=Avg, 3= both  ');

% logic.tempDelay=input('Together=0 or Spaced in Time=1  ');
logic.useMouse=input('Using mouse or eye 1=mouse, 2=eye  ');
if logic.useMouse==2 && logic.isDemo==2
    logic.savePupil=input('Save Pupil?: 1=yes, 2=no ');
end

if logic.isDemo==1
    logic.nBlocks = 2;  %1 for movie demo, 2 for training  
    logic.trialsPerBlock=75; %150 seems to get through enough examples
    %logic.ITI=.45;
    logic.durationTarget= .15;
end



logic.decisiontime_max = decisiontime_max;
if logic.useMouse==2;
if logic.savePupil==1    
    [subID, EDFfilename] = MKEyelinkCalibrate();
logic.EDFfilename=EDFfilename;
else
CPEyelinkCalibrateTest(); 
end
end
% Experiment paradigm
[tree, list] = configureMemTask(logic, isClient); 


%% Execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();
