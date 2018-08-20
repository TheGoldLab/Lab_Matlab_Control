function createCoherenceTrials(state)
% createCoherenceTrials(state)
% 
% This function creates the trials for the coherence part of the
% experiment. It will create a list of trials (coherence and direction
% pairs) and shuffle them. This is done by generating equal amounts of
% trials per coherence/direction pairing. Then, we convert these pairings
% into structs so that we can easily shuffle the order. Doing this
% pre-generation of stimuli guarantees that we get an equal number of
% stimuli for each direction of motion.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 10/2/17    xd  wrote it

tempCoherences = repmat(state{'Coherence'}{'coherences'}',state{'Coherence'}{'trialsPerCoherencePerDirection'}*2,1);
tempDirections = 180 * ones(length(tempCoherences),1);
tempDirections(1:end/2) = 0;
trials = [tempCoherences tempDirections];
trials = num2cell(cell2struct(num2cell(trials),{'coherence','direction'},2));
trials = trials(randperm(length(trials)));
state{'Coherence'}{'trials'} = trials;

end

