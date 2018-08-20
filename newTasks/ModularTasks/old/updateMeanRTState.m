function updateMeanRTState(state)
% updateMeanRTState(state)
% 
% This function updates the counter and flags related to the meanRT part of
% the experiment.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 10/2/17    xd  wrote it

%% Load params
counter = state{'MeanRT'}{'counter'};
numTrials = state{'MeanRT'}{'numTrials'};

%% Update params
counter = counter + 1;
state{'MeanRT'}{'counter'} = counter;
if counter > numTrials
    
    % Set flag to false
    state{'Flag'}{'meanRT'} = false;
    
    save('tempSaveFile','state');

    
    % Update meanRT for SAT/BIAS
    trials = state{'MeanRT'}{'trials'};
    totalTime = 0;
    for ii = 1:length(trials)
        rt = trials{ii}.mglStimFinishTime - trials{ii}.mglStimStartTime;
        totalTime = totalTime + rt;
    end
    avgTime = totalTime / length(trials);
    state{'MeanRT'}{'value'} = avgTime; % Units in ms right now
end

end

