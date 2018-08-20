function [trial,set,trialCounter] = getCurrentTrial(state)
% [trial,set,trialCounter] = getCurrentTrial(state)
% 
% Find the current trial that the experiment is on. This is done by
% checking the various boolean flags to find which part of the experiment
% is occurring (since they are ordered sequentially). Then, the set of
% trials and counter for that part of the experiment is retrieved and
% returned as outputs.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% Outputs:
%   trial  -  struct containing information about the current trial
%   set    -  string representing the current part of the experiment
%   trialCounter  -  integer for the index of the current trial
%
% 10/9/17    xd  wrote it

%% Get flags
questFlag      = state{'Flag'}{'QUEST'};
meanRTFlag     = state{'Flag'}{'meanRT'};
coherenceFlag  = state{'Flag'}{'coherence'};
SATBIASFlag    = state{'Flag'}{'SAT/BIAS'};

%% Find experiment part
if questFlag
    set = 'Quest';
elseif meanRTFlag
    set = 'MeanRT';
elseif coherenceFlag
    set = 'Coherence';
elseif SATBIASFlag
    set = 'SAT/BIAS';
end

%% Load stimulus based on which set
trialCounter = state{set}{'counter'};
trials = state{set}{'trials'};
trial  = trials{trialCounter};

end

