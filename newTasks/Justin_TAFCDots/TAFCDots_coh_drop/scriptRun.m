
%currently there is no timeout, free-response paradigm
addpath(genpath(fullfile('..','Lab-Matlab-Control')));
addpath(genpath(fullfile('..','mgl')));

if ~exist('scriptRunValues','dir')
    mkdir('scriptRunValues');
end
%Decision_Time
decisiontime_max = inf;
save('scriptRunValues/DT.mat','decisiontime_max')

%Specify gatherTAFCDotsSubInfoQuest information
%Will be used to create the save file information.
tag = 'Justin';
id = '44';
session = 1; %Will increment if same session save exists
foldername ='TAFCDotsData'; %What folder to save into
save('scriptRunValues/gatherinfo.mat','tag','id','session','foldername');

%TAFCDotsLogic
name = 'TAFC Reaction Time Perceptual Task';
nBlocks = 1;
trialsPerBlock = 300;
H = 2; %Hazard Rate
coherence = 100; %Percent of dots moving in stimulus direction
%Justin: This value is not used anymore
duration = 1; %length of time dots are shown
practiceN = 0;

%minT = 1;
%maxT = 1;
%coherenceset = [0 0 0]; %Use if we are switching between multiple
%coherences. Uncomment code in TAFCDotsLogic and TAFCDotsMainDemo.m

save('scriptRunValues/logic_values.mat','name','nBlocks', 'trialsPerBlock','H', ...
    'duration', 'practiceN', 'coherence');

%QUEST Variables
tGuess = .4; %Threshold estimate (prior)
tGuessSd =10; %standard deviation of the guess
pThreshold=.65;
beta=3.5;delta=0.01;gamma=0.5;
grain=.5;
range=50;

questTrials = 100;
save('scriptRunValues/quest_values.mat','tGuess','tGuessSd','pThreshold','beta','delta','gamma',...
    'questTrials','grain','range');

%cohDrop Variables
coh_high = 80;
coh_low = 15;
length_of_drop = .5;
length_of_high = 1;
minT = 3;
maxT = 4;
H3 = 1/5;
%if you want natural TAC. Change configure to hardcode TAC as 0 in
%configStartTrial
cp_minT = 0;
cp_maxT = 1;
cp_H3 = 1/2;

save('scriptRunValues/ch_values.mat','coh_high','coh_low','length_of_drop',...
   'minT','maxT','H3','cp_minT','cp_maxT','cp_H3','length_of_high');


%isClient
isClient = 0;
save('scriptRunValues/isClient.mat','isClient');
TAFCDotsMainDemo()
