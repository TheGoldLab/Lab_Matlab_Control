function RTDstartTrial(datatub)
% RTDstartTrial(datatub)
%
% RTD = Response-Time Dots
%
% Set up a trial, including preparing graphics, timing, etc.
%
% Inputs:
%   datatub - A topsGroupedList object containing experimental parameters
%                 as well as data recorded during the experiment.
% 
% 5/11/18 created by jig

%% ---- Get current task/trial information
% The task is a topsTreeNode. The useful data are in thisTask.nodeData.
%  See RTDConfigureTasks for details
task = datatub{'Control'}{'currentTask'};
trial = task.nodeData.trialData(task.nodeData.currentTrial);

%% ---- Prepare dots stimulus
%
% Possibly use reference coherence (e.g., from Quest)
if ~isfinite(trial.coherence)
   trial.coherence = datatub{'Task'}{'referenceCoherence'};
end

% Save the coherence and direction to the dots object in the stimuli ensemble
stimulusEnsemble = datatub{'Graphics'}{'stimulusEnsemble'};
inds = datatub{'Graphics'}{'stimulus inds'};
stimulusEnsemble.setObjectProperty('coherence', trial.coherence, inds(3));
stimulusEnsemble.setObjectProperty('direction', trial.direction, inds(3));

% Prepare to draw dots stimulus, use return value to sync time
stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow);

%% ---- Set the targets foreperiod
% Randomly sample a duration from an exponential distribution with bounds
task.nodeData.stateMachine.editStateByName('showTargets', 'timeout', ...
   datatub{'Timing'}{'showTargetForeperiodMin'} + ...
   min(exprnd(datatub{'Timing'}{'showTargetForeperiodMean'}), ...
   datatub{'Timing'}{'showTargetForeperiodMax'}));

%% ---- Flush the UI
ui = datatub{'Control'}{'ui'};
ui.flushData();
kb = datatub{'Control'}{'keyboard'};
kb.flushData();

%% ---- Save times
[trial.time_local_trialStart, ...
   trial.time_screen_trialStart, ...
   trial.time_screen_roundTrip, ...
   trial.time_ui_trialStart] = ...
   RTDsyncTiming(datatub{'Graphics'}{'screenEnsemble'}, ui);

%% ---- Conditionally send TTL pulses with info about task, trial counters
if datatub{'Input'}{'sendTTLs'}
   timeBetweenTTLPulses = datatub{'dOut'}{'timeBetweenTTLPulses'};
   trial.time_TTLBlock = sendTTLPulses(taskCounter, timeBetweenTTLPulses);
   trial.time_TTLTrial = sendTTLPulses(mod(trialCounter,3), timeBetweenTTLPulses);
end

%% ---- Re-save the trial
task.nodeData.trialData(task.nodeData.currentTrial) = trial;

%% ---- Show information about the task/trial
disp(sprintf('%s (%d/%d): trial %d of %d, coh=%d, dir=%d', ...    
    task.name, task.nodeData.taskNumber, length(task.caller.children), ...
    task.nodeData.currentTrial, size(task.nodeData.trialData, 1), ...
    trial.coherence, trial.direction))

