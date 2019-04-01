
%Adjust-1: set to your own location of Lab-Matlab-Control and mgl
addpath(genpath(fullfile('..','Lab-Matlab-Control')));
addpath(genpath(fullfile('..','mgl')));

%Creates scriptRunValues folder if it doesn't exist
if ~exist('scriptRunValues','dir')
    mkdir('scriptRunValues');
end

% Set Decision_Time
decisiontime_max = 1;
save('scriptRunValues/DT.mat','decisiontime_max')

%Specify gatherTAFCDotsSubInfoQuest information
%Will be used to name data file.
tag = 'Justin';
id = '22';
session = 1; %Will be incremented if same session save exists
foldername ='TAFCDotsData'; %What folder to save into
save('scriptRunValues/gatherinfo.mat','tag','id','session','foldername');

%TAFCDotsLogic
name = 'TAFC Reaction Time Perceptual Task';
nBlocks = 1;
trialsPerBlock = 2;
H = .1; %Hazard Rate
coherence = 50; %Percent of dots moving in stimulus direction
duration = 4; %length of time dots are shown
practiceN = 0;

save('scriptRunValues/logic_values.mat','name','nBlocks', 'trialsPerBlock','H', ...
    'duration', 'practiceN', 'coherence');

%isClient
isClient = 0;
save('scriptRunValues/isClient.mat','isClient');
TAFCDotsMainDemo()
