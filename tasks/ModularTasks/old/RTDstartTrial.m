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
trial = task.trialData(task.trialIndex);

%% --- Get ui objects
ui = datatub{'Control'}{'userInputDevice'};
kb = datatub{'Control'}{'keyboard'};

%% ---- Print useful information
% Show information about the task/trial
msg = sprintf('%s (%d/%d): trial %d of %d, dir=%d', ...
   task.name, task.taskIndex, length(task.caller.children), ...
   task.trialCount, numel(task.trialData)*task.trialIterations, ...
   trial.direction);
    
%% ---- Task-specific preparations 
% 
% Note that we could have different startTrial functions for each task, but
%  it is nice to see everything in one file
if strcmp(task.taskData.taskType, 'dots')
    
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
    task.taskData.stateMachine.editStateByName('showTargets', 'timeout', ...
        datatub{'Timing'}{'showTargetForeperiodMin'} + ...
        min(exprnd(datatub{'Timing'}{'showTargetForeperiodMean'}), ...
        datatub{'Timing'}{'showTargetForeperiodMax'}));
    
    % Add information about the coherence
    msg = sprintf('%s, coh=%.1f', msg, trial.coherence);
    
else % if strcmp(task.taskData.taskType, 'saccade')
    
    %% ---- Prepare saccade task
    %
    % Turn on t1 only, set location
    stimulusEnsemble = datatub{'Graphics'}{'saccadeStimuliEnsemble'};
    inds = datatub{'Graphics'}{'saccadeStimuli inds'};
    
    % Get x,y location of center of target
    targetOffset = datatub{'SaccadeTarget'}{'sacOffset'};
    x = datatub{'FixationCue'}{'xDVA'} + targetOffset * cosd(trial.direction);
    y = datatub{'FixationCue'}{'yDVA'} + targetOffset * sind(trial.direction);
    stimulusEnsemble.setObjectProperty('xCenter', x, inds(2));
    stimulusEnsemble.setObjectProperty('yCenter', y, inds(2));
    
    % Update gaze window
    ui.defineCompoundEvent('tcWindow', 'centerXY', [x y]);
    
    % Update stateMachine to jump to VGS-/MGS- specific states
    editStateByName(task.taskData.stateMachine, 'holdFixation', ...
        'next', [task.name 'showTarget']);    
end

%% ---- Show the message
disp(' ');
disp(msg)

%% ---- Flush the UI and deactivate all compound events (gaze windows)
kb.flushData();
ui.flushData();
ui.deactivateCompoundEvents();

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
    for pp = 1:task.taskNumber
        dOut.sendTTLPulse(channel);
        pause(timeBetweenTTLs);
    end
    
    % Send pulses corresponding to the trial number mod 3 (just cuz)
    %  flip order to end with pulse and save the time
    for pp = 1:task.trialCount
        pause(timeBetweenTTLs);
        trial.time_TTLFinish = dOut.sendTTLPulse(channel);
    end
end

%% ---- Re-save the trial
task.trialData(task.trialIndex) = trial;
