
%currently there is no timeout, free-response paradigm
addpath(genpath(fullfile('..','Lab-Matlab-Control')));
addpath(genpath(fullfile('..','mgl')));
addpath(genpath(fullfile('..','..','mQUESTPlus')));

if ~exist('scriptRunValues','dir')
    mkdir('scriptRunValues');
end
%Decision_Time
decisiontime_max = inf;

%1 - Psychtoolbox Quest
%2 - Custom Quest
%3 - Quest +
which_quest = 3;
save('scriptRunValues/DT.mat','decisiontime_max', 'which_quest')

%Specify gatherTAFCDotsSubInfoQuest information
%Will be used to create the save file information.
tag = 'Justin';
id = '43';
session = 1; %Will increment if same session save exists
foldername ='TAFCDotsData'; %What folder to save into
save('scriptRunValues/gatherinfo.mat','tag','id','session','foldername');

%TAFCDotsLogic
name = 'TAFC Reaction Time Perceptual Task';
nBlocks = 1;
trialsPerBlock = 50;
H = 0; %Hazard Rate
coherence = 100; %Percent of dots moving in stimulus direction
duration = .5; %length of time dots are shown
practiceN = 0;

%minT = 1;
%maxT = 1;
%coherenceset = [0 0 0]; %Use if we are switching between multiple
%coherences. Uncomment code in TAFCDotsLogic and TAFCDotsMainDemo.m

save('scriptRunValues/logic_values.mat','name','nBlocks', 'trialsPerBlock','H', ...
    'duration', 'practiceN', 'coherence');

%QUEST Variables
tGuess = 33; %Threshold estimate (prior)
tGuessSd =100; %standard deviation of the guess
pThreshold=.65;
beta=3.5;delta=0.01;gamma=0.5;
grain=.5;
range=100;
questTrials = 20;
plotIt=1;
save('scriptRunValues/quest_values.mat','tGuess','tGuessSd','pThreshold','beta','delta','gamma',...
    'questTrials','grain','range','plotIt');

%Custom Quest Variables
X = 0:1:100;
threshold_true = 50;
gamma = .5;
beta = 15;
epsilon = -2;
delta = 0.01;
grain = 60;

mu = 16;
sigma = 100;
save('scriptRunValues/quest_custom_values.mat','X','threshold_true','gamma','beta',...
    'epsilon','delta','mu','sigma','grain');


%isClient
isClient = 0;
save('scriptRunValues/isClient.mat','isClient');
TAFCDotsMainDemo()
