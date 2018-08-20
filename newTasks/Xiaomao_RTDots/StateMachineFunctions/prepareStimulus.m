function prepareStimulus(state,set)
% prepareStimulus(state)
%
% This function creates the moving dots stimulus before each trial. The
% parameters of the stimulus has been precalculated and stored in the state
% variable. A counter also exists that allows us to keep track of which
% trial we are on.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%   set    -  string that determines which part of the experiment we are
%             on. This can be 'MeanRT', 'Coherence', or 'SAT/BIAS'
%
% 9/16/17   xd  moved out of demoStimulusEyelink

%% Load the trial we are on.
counter = state{set}{'counter'};
trials  = state{set}{'trials'};
trial   = trials{counter};

%% Create stimulus and save into state
createStimulusFrame(state,trial.coherence,trial.direction);

end


