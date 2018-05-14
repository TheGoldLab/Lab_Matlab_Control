function updateCoherenceState(state)
% updateCoherenceState(state)
% 
% Updates the counter for the coherence part of the experiment. This part
% is rather straightforward since here are no additional fields that need
% to be updated once this part has finished.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 10/3/17    xd  wrote it

%% Load params
counter = state{'Coherence'}{'counter'};
numTrials = state{'Coherence'}{'numTrials'};

%% Update
counter = counter + 1;
state{'Coherence'}{'counter'} = counter;
if counter > numTrials
    state{'Flag'}{'coherence'} = false;
    save('tempSaveFile','state');
end

end

