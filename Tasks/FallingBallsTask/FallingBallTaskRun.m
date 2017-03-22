%Falling Ball Task
clear all;
close all;
clc;

% subject = input('Subject: ','s');
logic.H = input('Hazard Rate? ');
logic.nTrials = input('How many Trials would you like? ');
logic.observation = input('How many observation trials would you like? ');
logic.R = input('Ratio of Sigma Values? ');
logic.Sigma0  = input('Sigma value for the Red ball? ');

isClient = 0;



[tree, list] = FallingBallTaskPrediction(logic, isClient); 



%% Post-Processing

%This is the X position of the target index when user commits
%The target data is set to 99 if balls are falling automatically
Data.target = list{'input'}{'target'};
%This is the actual X position of the Green ball when it falls
Data.sample = list{'input'}{'sample'};
%This is the actual X postion of the Red ball when it falls
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
%This is a list of which trials were changepoints
Data.changepoint = list{'stimulus'}{'changepoint'};


%Saves the above input values
Data.R      = logic.R;
Data.Sigma0 = logic.Sigma0;
Data.Sigma  = logic.R*logic.Sigma0;

% save(subject)