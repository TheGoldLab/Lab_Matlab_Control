%%%%%%
% v1 %
%%%%%%
% Falling Ball Task for One Run Length Project 
% Developed by Chris Pizzica and Takahiro Doi in 2017 
%
% Change the task parameter values below if necessary 
% 
% 
% _v1 (04-18-2017)
% used to get the first set of the preliminary data

% Notes for Chris about my edits (Taka)
% [x] Get the version number from the script name and calls the same version
%     of the prediction/estimation task file. 
% [x] Save the date and time info
% [x] Save the mfilename 
% [x] Introduced "Experiment Idetifier (expID)", which goes into the mat file name
% [x] Prompt for choosing between the prediction versus estimation
% [x] Add the Exp Identifier and Prediction or Estimation into prmorder_filename file
%     name and data file name
% [x] Add exception routines when the mismatch was found between the user
%     input to the "first time question" and if the param order table exists or
% [x]  'Y' is permitted in addition to 'y' to create the prmorder_filename mat file
% [x] Count existing data matfiles to get the correct block number
% [x] cd to the FallingBallsTask folder to make sure I can get the
%     function handle to the task script
% [x] Organized path a bit
% [x] Use R instead of Sigma for data file name 
% [x] Stop using Logic Class just to get the set of H and define it 
%     within the script (just as other key variables are defined here)
% [x] Bug fix: hazard and sigmaratio are now permuted simultaneously 
% [x] Save/Load only prmtable to the prmorder file to prevent overwrite
%     other variables 

clear all;
close all;
clc;

project_path = '/Users/joshuagold/Documents/MATLAB/Tasks/FallingBallsTask/';
% project_path = '/Volumes/KINGSTON/';
data_path    = [project_path,'data',filesep];
cd(project_path)

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% TASK PARAMTERS %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
expID = 'Preliminary1';
Sigma0         = 1;
set_SigmaRatio = [0.5 2];
set_H          = [1];
% nTotalTrials = 280;
% nObsTrials   = 80;
nTotalTrials = 20;
nObsTrials   = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%

% getting the version number from the mfilename
mf = mfilename;
str_ver = mf(strfind(mf,'_v')+2:end);

% A couple of user prompt
subject   = input('Subject: ','s');
task_type_char = input('Prediction or Estimation? p/e?: ','s');
if any(strcmp({'p','P'},task_type_char))
    task_type = 'Prediction';
elseif any(strcmp({'e','E'},task_type_char))
    task_type = 'Estimation';    
else
    error('Please answer with either p or e.');
end
FirstTime = input('Is this your first time? y/n?: ','s');
%So this is just creating a two arrays with a random permutation from 1 to
%11. The arrays are then combined and shuffled to create a random order for
%the hazard and sigma combinations a subject experiences. If it isn't the
%first time for a subject it jumps to the else statement and loads their
%previously generated permuation list. 
s1 = {'y','Y'};
prmorder_filename = sprintf('FBT_prmorder_%s_%s_%s',task_type,expID,subject);
tmporderfile = dir([data_path,prmorder_filename,'.mat']);
n_Hazard = length(set_H);
if any(strcmp(s1,FirstTime))
    if ~isempty(tmporderfile)
        Check1 = input('It seems this is not your first time. Are you sure you want to start over? y/n','s');
        if ~any(strcmp(Check1,{'Y','y'}))
            disp('Abort the experiment.');
            return
        end
    end
    % create a table of hazard rate and sigma ratio with a randomized
    % order
    prmtable = combvec(set_H,set_SigmaRatio)';
    lentable = size(prmtable,1); % length of prm combinations 
    prmtable = prmtable(randperm(lentable),:); % randomized order 
    disp('Creating subject permutation order...');
    matfileinfo.mfilename = mfilename;
    matfileinfo.clock = clock;
    save([data_path, prmorder_filename,'.mat'],'prmtable','matfileinfo');
else
    if isempty(tmporderfile)
        disp('The param order file does not exist. This must be your first time. Abort the experiment.');
        return;
    end
    load([data_path, prmorder_filename,'.mat']);
    disp('Loading subject permutation order...')
end

%Number of total trials
logic.nTrials = nTotalTrials;
%Number of trials before testing beings
logic.observation = nObsTrials;

% The Block Number is which block the subject is now on.
% Count existing data files and increment 1 
datafilename_pre  = sprintf('FBT_data_%s_%s_%s_',task_type,expID,subject);
tmpdatafile = dir([data_path,datafilename_pre,'*.mat']);
BlockNumber = length(tmpdatafile)+1;
disp(['Block Number: ',num2str(BlockNumber)]);
if BlockNumber > length(prmtable)
    disp('You have already finished all conditions!');
    return;
end
%Uses block number to jump to the next Hazard and Sig value
Dim.H = 1;
Dim.R = 2;
logic.H = prmtable(BlockNumber,Dim.H);
logic.R = prmtable(BlockNumber,Dim.R);
logic.Sigma0  = Sigma0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% only temporary code used for TakaDoi because of a bug in the eariler version of the script
%%% move my current data to data/tmp
% partoffileH = logic.H * 100;
% partoffileR = logic.R * 100;
% datafilename_post = sprintf('H%.3g_R%.3g',partoffileH,partoffileR);
% tmpdatafile2 = dir(['data/tmp/',datafilename_pre,datafilename_post,'.mat']);
% if ~isempty(tmpdatafile2)
%     source = ['data/tmp/',datafilename_pre,datafilename_post,'.mat'];
%     destination = ['data/',datafilename_pre,datafilename_post,'.mat'];
%     movefile(source,destination);
%     disp('The mat file was found. Move the file from data/tmp to data');
%     return
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


isClient = 0;

taskfilename = ['FallingBallTask',task_type,'_v',str_ver,'.m'];
assert(exist(taskfilename,'file')==2,[taskfilename, ' does not exist on Matlab search path.']);
fhandle = str2func(taskfilename(1:end-2));
[tree, list] = fhandle(logic, isClient); 
% [tree, list] = FallingBallTaskEstimation(logic, isClient); 
Data.Subject    = subject;
Data.Hazardlist = set_H; % Randomized order of a set of hazard
Data.Sigmalist  = set_SigmaRatio;
Data.TestedOrder = prmtable;
Data.BlockNumber = BlockNumber;
Data.nTotalTrials = nTotalTrials;
Data.nObsTrials   = nObsTrials;

%% Post-Processing

%This is the X position of the target index when user commits
%The target data is set to 99 if balls are falling automatically
Data.target = list{'input'}{'target'};
%This is the actual X position of the Green ball when it falls
Data.sample = list{'input'}{'sample'};
%This is the generative mean
Data.mean   = list{'input'}{'mean'};
%This is the trials counter
Data.counter = list{'timing'}{'counter'};
%This is a users mouse movements during a test trial
% Data.Mouse = list{'mouse'}{'movement'};
%This is the difference between a users commit position and the green ball
Data.feedback_number = list{'target'}{'feedback number'};
%Cell array: Col 1 is the trial number, Col 2 is the mouse movements for
%the individual trials
Data.MouseCell = list{'trial'}{'mouse position'};

Data.ChangePoint = list{'stimulus'}{'changepoint'};

%Saves the above input values
Data.R      = logic.R;
Data.Sigma0 = logic.Sigma0;
Data.Sigma  = logic.R*logic.Sigma0;
Data.Hazard = logic.H;

% other info
Data.info.mfilename = mfilename;
Data.info.clock     = clock;

%The multiplication is just to prevent a decimal from appearing in the file name
partoffileH = logic.H * 100;
partoffileR = logic.R * 100;
datafilename_post = sprintf('H%.3g_R%.3g',partoffileH,partoffileR);
save([data_path, [datafilename_pre,datafilename_post], '.mat']);

if BlockNumber == length(prmtable)
    disp('Congrats! You are done!');
end