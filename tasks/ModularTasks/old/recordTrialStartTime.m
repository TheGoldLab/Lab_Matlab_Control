function recordTrialStartTime(state)
% recordTrialStartTime(state)
%
% This function records the start time of every trial. Trial start times
% will only be recorded in the actual presentation stage and not during the
% QUEST stage.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/27/17    xd  wrote it

isQuest = state{'Quest'}{'flag'};
if ~isQuest
    trialCount = state{'Stimulus'}{'counter'};
    trials = state{'Stimulus'}{'trials'};
    trial = trials{trialCount};
    trial.mglTrialStartTime =  mglGetSecs;
    e = Eyelink('NewestFloatSample');
    trial.eyelinkTrialStartTime = e.time;
    trials{trialCount} = trial;
    state{'Stimulus'}{'trials'} = trials;
end

end

