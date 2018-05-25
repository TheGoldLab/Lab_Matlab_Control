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

if strcmp(task.nodeData.taskType, 'dots')
   
   %% ---- Prepare dots task
   %
   % Possibly use reference coherence (e.g., from Quest)
   if ~isfinite(trial.coherence)
      trial.coherence = datatub{'Task'}{'referenceCoherence'};
   end
   
   % Save the coherence and direction to the dots object in the stimuli ensemble
   stimulusEnsemble = datatub{'Graphics'}{'dotsStimuliEnsemble'};
   inds = datatub{'Graphics'}{'dotsStimuli inds'};
   stimulusEnsemble.setObjectProperty('coherence', trial.coherence, inds(3));
   stimulusEnsemble.setObjectProperty('direction', trial.direction, inds(3));
   
   % Prepare to draw dots stimulus, use return value to sync time
   stimulusEnsemble.callObjectMethod(@prepareToDrawInWindow);
   
   % Set the targets foreperiod
   % Randomly sample a duration from an exponential distribution with bounds
   task.nodeData.stateMachine.editStateByName('showTargets', 'timeout', ...
      datatub{'Timing'}{'showTargetForeperiodMin'} + ...
      min(exprnd(datatub{'Timing'}{'showTargetForeperiodMean'}), ...
      datatub{'Timing'}{'showTargetForeperiodMax'}));
   
   % Show information about the task/trial
   disp(sprintf('%s (%d/%d): trial %d of %d, coh=%.1f, dir=%d', ...
      task.name, task.nodeData.taskNumber, length(task.caller.children), ...
      task.nodeData.currentTrial, size(task.nodeData.trialData, 1), ...
      trial.coherence, trial.direction))
   
else % if strcmp(task.nodeData.taskType, 'saccade')
   
   %% ---- Prepare saccade task
   %
   % Turn on t1 only, set location
   stimulusEnsemble = datatub{'Graphics'}{'saccadeStimuliEnsemble'};
   inds = datatub{'Graphics'}{'saccadeStimuli inds'};
   fixX = datatub{'FixationCue'}{'xDVA'};
   fixY =  datatub{'FixationCue'}{'yDVA'};
   targetOffset = datatub{'SaccadeTarget'}{'offset'};
   
   stimulusEnsemble.setObjectProperty('xCenter', ...
      fixX + targetOffset * cosd(trial.direction), inds(2));
   stimulusEnsemble.setObjectProperty('yCenter', ...
      fixY + targetOffset * sind(trial.direction), inds(2));
   
   % Update stateMachine to jump to VGS-/MGS- specific states
   editStateByName(task.nodeData.stateMachine, 'holdFixation', ...
      'next', [task.name 'showTarget']);
   
   % Show information about the task/trial
   disp(sprintf('%s (%d/%d): trial %d of %d, dir=%d', ...
      task.name, task.nodeData.taskNumber, length(task.caller.children), ...
      task.nodeData.currentTrial, size(task.nodeData.trialData, 1), ...
      trial.direction))
end

%% ---- Flush the UI
ui = datatub{'Control'}{'ui'};
ui.flushData();
kb = datatub{'Control'}{'keyboard'};
kb.flushData();

%% ---- Save times
[trial.time_local_trialStart, trial.time_screen_trialStart, ...
   trial.time_screen_roundTrip, trial.time_ui_trialStart] = ...
   RTDsyncTiming(datatub{'Graphics'}{'screenEnsemble'}, ui);

%% ---- Conditionally send TTL pulses with info about task, trial counters
if datatub{'Input'}{'sendTTLs'}
   dOut            = datatub{'dOut'}{'dOutObject'};
   channel         = datatub{'dOut'}{'TTLChannel'};
   timeBetweenTTLs = datatub{'Input'}{'timeBetweeenTTLs'};
   
   % Send pulses corresponding to the task number
   for pp = 1:task.nodeData.taskNumber
      dOut.sendTTLPulse(channel);
      pause(timeBetweenTTLs);
   end
   
   % Send pulses corresponding to the trial number mod 3 (just cuz)
   %  flip order to end with pulse and save the time
   for pp = 1:task.nodeData.currentTrial
      pause(timeBetweenTTLs);
      trial.time_TTLFinish = dOut.sendTTLPulse(channel);
   end
end

%% ---- Re-save the trial
task.nodeData.trialData(task.nodeData.currentTrial) = trial;
