% function [pfData, pulseData] = runPulsesExper
%%  runPulsesExper.m
%    glue code to combine:
%    1. configThresh (which estimates the psychometric fxn)
%    2. figure out the appropriate threshold and pulse coh
%    3. configPulses (which presents pulses of coh as fxn of time)
%    4. saves all the data
%    5. display the data in various ways
%
%   updated 2010-09-20 YL

%% -1. Control Code
clear all;

REMOTE_MODE = 1;
DEBUG_MODE = 0;
FULL_SCREEN = 1;
QUERY_CONF = 1;             % run the code for querying confidence
SAVE_MODE = 0;              % 0 == do the save in runPulsesExper (naming may be counterintuitive)

% important constants for the experiments
THRESH = 1;                 % sensitivity (in d') at threshold coh
PULSE = 1.5;                % sensitivity (in d') at pulse coherence

% other constants
DIR_NAME = '/Volumes/XServerData/Psychophysics/Yin Data/';
F_NAME = 'pulsExper';

%% 0. ask for sbj's name
subjName = input('Please type your initials and press [ENTER]: ', 's');
subjName = lower(subjName);

%% 1. configThresh
% run the config file
[pfTree, pfList] = configThresh(REMOTE_MODE,DEBUG_MODE,FULL_SCREEN,QUERY_CONF,SAVE_MODE);
pfTree.run;

% 1.5. organize some of the data from configThresh
stim = pfList{'data'}{'stim'};
coh = pfList{'data'}{'coh'};
dir = pfList{'data'}{'dir'};
choice = pfList{'data'}{'choice'};
confid = pfList{'data'}{'confid'};

pfData = struct(...                     % psychometric fxn data
    'stim', stim,...
    'coh', coh,...
    'dir', dir,...
    'choice', choice,...
    'confid', confid,...
    'date', now,...
    'subj', subjName  );

%% 2. figure out threshold and pulse coh
[threshCoh, pulseCoh] = makePF(coh,dir,choice,false,THRESH,PULSE);

%% 3. configPulses
input('Please wait for further instructions.');

% run the config
[pulseTree, pulseList] = configPulses(threshCoh,pulseCoh,REMOTE_MODE,DEBUG_MODE,FULL_SCREEN,QUERY_CONF,SAVE_MODE);
pulseTree.run;

% 3.5. organize some of the data from configPulses
stim = pulseList{'data'}{'stim'};
coh = pulseList{'data'}{'coh'};
dir = pulseList{'data'}{'dir'};
choice = pulseList{'data'}{'choice'};
cohcode = pulseList{'stim'}{'coh'};
tcoh = pulseList{'data'}{'threshCoh'};
pcoh = pulseList{'data'}{'pulseCoh'};
confid = pulseList{'data'}{'confid'};

fname = pulseList{'control'}{'fname'};
dname = pulseList{'control'}{'dirName'};
pulseData = struct(...                      % pdata = 'pulse data'
    'stim', stim,...
    'coh', coh,...                      % coded as '1' '2' '3', etc.
    'cohcode', {cohcode},...              % allows us to 'decode' the coherence train in 'coh'
    'dir', dir,...
    'choice', choice,...
    'confid', confid,...
    'tcoh', tcoh,...
    'pcoh', pcoh,...
    'date', now,...
    'subj', subjName  );


%% 4. save all the data
save([DIR_NAME datestr(now,30) '_' subjName '_' F_NAME '.mat'], ...
    'pfData', 'pulseData');

%% 5. display the data in interesting ways
makePF(pfData);
dispPulses(pulseData);