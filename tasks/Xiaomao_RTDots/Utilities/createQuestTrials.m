function createQuestTrials(state)
% createQuestTrials(state)
% 
% Create a list of trial structs for the QUEST portion of the stimuli.
% Because the coherence levels for QUEST are generated dynamically, these
% structs will only contain the direction field.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 10/2/17    xd  wrote it

direction = 180 * ones(state{'Quest'}{'numTrials'},1);
direction(1:end/2) = 0;
direction = direction(randperm(length(direction)));
trials = num2cell(cell2struct(num2cell(direction),{'direction'},2));
state{'Quest'}{'trials'} = trials;

end

