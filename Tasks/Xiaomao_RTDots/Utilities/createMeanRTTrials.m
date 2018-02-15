function createMeanRTTrials(state)
% createMeanRTTrials(state)
% 
% Create all the trials for the meanRT testing condition. Do this by
% creating the appropriate number of trials with identical coherences and
% the split evenly for both directions.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 10/2/17    xd  wrote it


tempDirection = 180 * ones(state{'MeanRT'}{'numTrials'},1);
tempDirection(1:end/2) = 0;
tempDirection = tempDirection(randperm(length(tempDirection)));
tempCoherence = state{'SAT/BIAS'}{'coherenceThreshold'} * ones(state{'MeanRT'}{'numTrials'},1);
trials = [tempCoherence tempDirection];
trials = num2cell(cell2struct(num2cell(trials),{'coherence','direction'},2));
state{'MeanRT'}{'trials'} = trials;

end

