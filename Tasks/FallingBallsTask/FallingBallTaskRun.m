%Falling Ball Task
clear all;
close all;
clc;

Order = Logic;
subject = input('Subject: ','s');
s1 = 'y';
FirstTime = input('Is this your first time? y/n?','s');
%So this is just creating a two arrays with a random permutation from 1 to
%11. The arrays are then combined and shuffled to create a random order for
%the hazard and sigma combinations a subject experiences. If it isn't the
%first time for a subject it jumps to the else statement and loads their
%previously generated permuation list. 
if strcmp(s1,FirstTime) == 1  
    firstperm = randperm(11);
    secondperm = randperm(11);
    HazardOrder = [firstperm secondperm];
    a(1:11) = 0.5;
    b(1:11) = 2;
    c = [a b];
    SigRatio = Shuffle(c);
    Horder = sprintf('%s_hazardorder',subject);
    disp('Creating subject permutation order...')
    save(['/Users/joshuagold/Documents/MATLAB/data/' Horder '.mat'])
else
    Horder = sprintf('%s_hazardorder',subject);
    load(['/Users/joshuagold/Documents/MATLAB/data/' Horder '.mat'])
    disp('Loading subject permutation order...')
end


%Number of total trials
logic.nTrials = 5;
%Number of trials before testing beings
logic.observation = 1;

%The Block Number is which block the subject is now on.
BlockNumber = input('Block? ');
%Uses block number to jump to the next Hazard and Sig value
logic.H = Order.H(HazardOrder(BlockNumber));
logic.R = SigRatio(BlockNumber);
logic.Sigma0  = 1;


isClient = 0;



[tree, list] = FallingBallTaskPrediction(logic, isClient); 
% [tree, list] = FallingBallTaskEstimation(logic, isClient); 
Data.Subject = subject;
Data.Hazardlist = Order.H(HazardOrder);

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

%The multiplication is just to prevent a decimal from appearing in the file name
partoffile = logic.H * 100;
partoffileSig = Data.Sigma*100;
filename = sprintf('FTBPredict_v1_%s_H%.3g_S%.3g',subject,partoffile,partoffileSig);
save(['/Users/joshuagold/Documents/MATLAB/data/' filename '.mat'])