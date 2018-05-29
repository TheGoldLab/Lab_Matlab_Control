function RTDshowFP(state)
% RTDshowFP(state)
%
% Show fixatoin point defined in configureGraphicsRTDots.m
%
% Inputs:
%   state      -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.

%% ---- Turn fp on, targets/dots off
stimulusEnsemble = state{'Graphics'}{'stimulusEnsemble'};
stimulusEnsemble.setObjectProperty('isVisible', true, state{'Graphics'}{'fixationCue ind'});

%% ---- Get the stimulus screen composite and run one iteration
stimulusScreenComposite = state{'Graphics'}{'stimulusScreenComposite'};
stimulusScreenComposite.run(1);

%% ---- Save timing information
trial = state{'Task'}{'currentTrial'};
trial.time_fpOn = mglGetSecs;
