function [tree, list] = ODR_TaskInfer(decisiontime_max)
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
logic.nBlocks = 1;      
logic.blockType= 2; %input('Random=1 or Dynamic=2: ');

if logic.blockType==1
        logic.trialsPerBlock=120;
        logic.H=1;
    else
        logic.trialsPerBlock= 1500 ;%2000;  
        logic.H=.15;
end



logic.isDemo=input('Demo?: 1=demo, 2=normaltask ');
logic.varDelay=input('Varriable delay? 1=no, 2=yes  ');
logic.useMouse=input('Using mouse or eye 1=mouse, 2=eye  ');
if logic.useMouse==2 && logic.isDemo==2
    logic.savePupil=input('Save Pupil?: 1=yes, 2=no ');
end

if logic.isDemo==1
    logic.nBlocks = 2;  %1 for movie demo, 2 for training  
    logic.trialsPerBlock=75; %150 seems to get through enough examples
    logic.H=.15;
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
[tree, list] = configureODRtaskInfer(logic, isClient); 


%% Execute the 2afc task by invoking run() on the top-level object
commandwindow();
tree.run();
