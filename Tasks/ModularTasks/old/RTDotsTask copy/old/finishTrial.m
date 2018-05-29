function string = finishTrial(state)
% string = finishTrial(state)
%
% This is run at the end of every trial and used to determine whether the
% state machine needs to update counters/flags for QUEST or for the actual
% experiment itself.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/20/17    xd  moved out of movingDotsTaskEyelinkCoherence.m

%% Change the display to a blank
duration = state{'Timing'}{'rest'};
string = '';
intertrial = state{'graphics'}{'intertrialBlank'};
intertrial.callObjectMethod(@prepareToDrawInWindow);
intertrial.run(duration);

%% Pull different flags
questFlag      = state{'Flag'}{'QUEST'};
meanRTFlag     = state{'Flag'}{'meanRT'};
coherenceFlag  = state{'Flag'}{'coherence'};
SATBIASFlag    = state{'Flag'}{'SAT/BIAS'};

%% Redirect according to flags
if questFlag
    string = 'updateQuestState';
elseif meanRTFlag
    string = 'updateMeanRTState';
elseif coherenceFlag
    string = 'updateCoherenceState';
elseif SATBIASFlag
    string = 'updateContextState';
end

end

