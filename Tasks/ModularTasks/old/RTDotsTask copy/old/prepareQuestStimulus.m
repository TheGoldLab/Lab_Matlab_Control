function prepareQuestStimulus(state)
% prepareQuestStimulus(state)
% 
% This function creates a stimulus according to QUEST, which automatically
% generates a coherence level to test at each and every trial. We will
% limit the coherence to between 0 and 100. This function does not display
% the stimulus and only prepares it so that presentStimulus.m can play it.
%
% Inputs:
%   state  -  topsGroupList object that contains information and parameters
%             regarding (but not limited to) the current trial
%
% 9/18/17    xd  wrote it

%% Extract the question object
q       = state{'Quest'}{'object'};
counter = state{'Quest'}{'counter'};
trials  = state{'Quest'}{'trials'};

%% Generate a new sample via QUEST
%
% Limit this sample to between 0 and 100
% tCoherence = QuestQuantile(q);
tCoherence = qpQuery(q);
tCoherence = min(100,max(0,tCoherence));
tDirection = trials{counter}.direction;

trials{counter}.coherence = tCoherence;
state{'Quest'}{'trials'} = trials;

%% Generate the moving dots stimulus
createStimulusFrame(state,tCoherence,tDirection);

end

