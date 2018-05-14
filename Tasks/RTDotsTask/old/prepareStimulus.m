function prepareStimulus(state)
% prepareStimulus(state)
%
% Generates the moving dots stimulus using the coherence and direction
% values given as parameters. The frame is then added to the state under
% 'graphics'. This allows the rest of the program to draw it when
% necessary.
%
% Inputs:
%   state      -  A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
% 10/2/17    xd  wrote it

%% Get current trial
taskArray = state{'task'}{'taskArray'};
taskCounter = state{'task'}{'taskCounter'};
trialCounter = state{'task'}{'trialCounter'};
trial = taskArray{2, taskCounter}(trialCounter);

%% Check for Quest to get coherence
if strcmp(taskArray{1, taskCounter}, 'Quest')
   
   % Generate a new sample via QUEST
   %  Limit this sample to between 0 and 100
   % tCoherence = QuestQuantile(q);
   trial.coherence = min(100, max(0, qpQuery(state{'Quest'}{'object'})));
   
elseif ~isfinite(trial.coherence)
   
   % Use the reference coherence (given or from Quest)
   trial.coherence = state{'task'}{'referenceCoherence'};
end

%% Save the coherence and direction to the dots object in the stimuli ensemble
stimuli = state{'graphics'}{'stimuli'};
dotsInd = state{'graphics'}{'movingDotsStimulus ind'};
stimuli.setObjectProperty('coherence', trial.coherence, dotsInd);
stimuli.setObjectProperty('direction', trial.direction, dotsInd);

%% Re-save the trial
taskArray{2, taskCounter}(trialCounter) = trial;
state{'task'}{'taskArray'} = taskArray;

end


