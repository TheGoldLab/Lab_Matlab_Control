function RTDendTrial(state)
% RTDendTrial(state)
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

%% ---- Get current trial information
taskArray = state{'Task'}{'taskArray'};
taskCounter = state{'Task'}{'taskCounter'};
trialCounter = state{'Task'}{'trialCounter'};
trial = taskArray{2, taskCounter}(trialCounter);

%% ---- Prepare dots stimulus

% Get coherence
if strcmp(taskArray{1, taskCounter}, 'Quest')
   
   % Generate a new sample via QUEST (limit to between 0 and 100)
   trial.coherence = min(100, max(0, qpQuery(state{'Quest'}{'object'})));
   
elseif ~isfinite(trial.coherence)
   
   % Use the reference coherence (given or from Quest)
   trial.coherence = state{'Task'}{'referenceCoherence'};
end

% Save the coherence and direction to the dots object in the stimuli ensemble
stimulusEnsemble = state{'Graphics'}{'stimulusEnsemble'};
dotsInd = state{'Graphics'}{'movingDotsStimulus ind'};
stimulusEnsemble.setObjectProperty('coherence', trial.coherence, dotsInd);
stimulusEnsemble.setObjectProperty('direction', trial.direction, dotsInd);

% prepare dots stimulus
stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow);

%% ---- CHECK FOR BLOCK START TO SET UP INSTRUCTIONS & DUMP DATA
%
% Get the state machine to define start state
stateMachine = state{'Control'}{'stateMachine'};
if trialCounter>1 || state{'Task'}{'repeatTrial'}>0

   % In the middle of the block, start at wait1 state
   stateMachine.startState = 'wait1';
else
   
   % Block beginning!
   %  start at the first state
   stateMachine.startState = 1;
   
end

%% ---- Log task/trial info
topsDataLog.logDataInGroup(taskCounter,  'task counter');
topsDataLog.logDataInGroup(trialCounter, 'trial counter');

%% ---- Flush the UI
ui = state{'Control'}{'ui'};
ui.flushData();

%% ---- Conditionally send TTL pulses with info about task, trial counters
if state{'Input'}{'sendTTLs'}
   timeBetweenTTLPulses = state{'dOut'}{'timeBetweenTTLPulses'};
   trial.TTLBlockTimes = sendTTLPulses(taskCounter, timeBetweenTTLPulses);
   trial.TTLTrialTimes = sendTTLPulses(mod(trialCounter,3), timeBetweenTTLPulses);
end

%% ---- Re-save the trial
taskArray{2, taskCounter}(trialCounter) = trial;
state{'Task'}{'taskArray'} = taskArray;

