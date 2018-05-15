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

disp(sprintf('RTDstartTrial : COHERENCE=%.2f, DIRECTION=%d', trial.coherence, trial.direction))

%% ---- Set the targets foreperiod
% Randomly sample a duration from an exponential distribution with bounds
task.nodeData.stateMachine.editStateByName('showTargets', 'timeout', ...
   datatub{'Timing'}{'showTargetForeperiodMin'} + ...
   min(exprnd(datatub{'Timing'}{'showTargetForeperiodMean'}), ...
   datatub{'Timing'}{'showTargetForeperiodMax'}));

%% ---- Flush the UI
ui = datatub{'Control'}{'ui'};
ui.flushData();

%% ---- Save times
% use the screen ensemble to get the (possibly remote) screen time
screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};

% Ask for the time from the screen object, but only accept it if it comes
% quickly
roundTrip = inf;
start = mglGetSecs;
timeout = false;
while roundTrip > 0.01 && ~timeout;
   before = mglGetSecs;
   screenTime = screenEnsemble.callObjectMethod(@getCurrentTime);
   after = mglGetSecs;
   roundTrip = after - before;
   timeout = (after-start) > 0.5;
end
trial.time_eye_trialFinish    = ui.getDeviceTime();
trial.time_screen_trialFinish = screenTime;
trial.time_local_trialFinish  = mean([before after]);
if timeout
   trial.time_is_confident = false;
end
%% ---- Conditionally send TTL pulses with info about task, trial counters
if datatub{'Input'}{'sendTTLs'}
   timeBetweenTTLPulses = datatub{'dOut'}{'timeBetweenTTLPulses'};
   trial.time_TTLBlock = sendTTLPulses(taskCounter, timeBetweenTTLPulses);
   trial.time_TTLTrial = sendTTLPulses(mod(trialCounter,3), timeBetweenTTLPulses);
end

%% ---- Re-save the trial
task.nodeData.trialData(task.nodeData.currentTrial) = trial;

