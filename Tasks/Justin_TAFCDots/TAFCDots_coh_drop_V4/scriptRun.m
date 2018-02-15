
% Last changepoint occurance is signalled with a yellow 

%currently there is no timeout, free-response paradigm
% addpath(genpath(fullfile('..','Lab-Matlab-Control')));
% addpath(genpath(fullfile('..','mgl')));

if ~exist('scriptRunValues','dir')
    mkdir('scriptRunValues');
end
%Decision_Time
decisiontime_max = inf;
save('scriptRunValues/DT.mat','decisiontime_max')

%Specify gatherTAFCDotsSubInfoQuest 
%Will be used to create the save file information.
tag = 'Justin';
id = '44';
session = 1; %Will increment if same session save exists
foldername ='TAFCDotsData'; %What folder to save into
save('scriptRunValues/gatherinfo.mat','tag','id','session','foldername');
duration = nan; %this value is overwritten and is unnecasry. Could remove

%TAFCDotsLogic
name = 'TAFC Reaction Time Perceptual Task';
nBlocks = 1;
trialsPerBlock = 100;
H = 2; %Hazard Rate
coherence = 100; %Percent of dots moving in stimulus direction
practiceN = 0;

save('scriptRunValues/logic_values.mat','name','nBlocks', 'trialsPerBlock','H', ...
    'duration', 'practiceN', 'coherence');

%cohDrop Variables
coh_high = 85;
coh_low = 12;
length_of_drop = .5;
length_of_high = 1;
minT = 4;
maxT = 8;
H3 = 1.5;
%if you want natural TAC. Change configure to hardcode TAC as 0 in
%configStartTrial
cp_minT = 0;
cp_maxT = 4;
cp_H3 = 4;
%0 - to disable the artificial changepoint (recommended for high hazard)
%1 - to enable the artificial changepoint (recommended for low hazard)
%artificial changepoint only occurs 50% of the time
TAC_on =1;
static_dot_reset = false;

save('scriptRunValues/ch_values.mat','coh_high','coh_low','length_of_drop',...
   'minT','maxT','H3','cp_minT','cp_maxT','cp_H3','length_of_high','TAC_on', 'static_dot_reset');


%isClient
isClient = 0;
save('scriptRunValues/isClient.mat','isClient');
TAFCDotsMainDemo()
