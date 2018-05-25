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

%% --- Get ui objects
ui = datatub{'Control'}{'ui'};
kb = datatub{'Control'}{'keyboard'};

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
    
    % Set the fixation spot to be small and white
    stimulusEnsemble.setObjectProperty('width', ...
        datatub{'FixationCue'}{'size'}.*[1 0.1], inds(1));
    stimulusEnsemble.setObjectProperty('height', ...
        datatub{'FixationCue'}{'size'}.*[0.1 1], inds(1));
    stimulusEnsemble.setObjectProperty('colors', ...
        [1 1 1], inds(1));
    
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
    
    % Get x,y location of center of target
    targetOffset = datatub{'SaccadeTarget'}{'sacOffset'};
    x = datatub{'FixationCue'}{'xDVA'} + targetOffset * cosd(trial.direction);
    y = datatub{'FixationCue'}{'yDVA'} + targetOffset * sind(trial.direction);
    stimulusEnsemble.setObjectProperty('xCenter', x, inds(2));
    stimulusEnsemble.setObjectProperty('yCenter', y, inds(2));
    
    % Set the fixation spot to be large and red
    stimulusEnsemble.setObjectProperty('width', ...
        datatub{'FixationCue'}{'size'}.*[1 0.3], inds(1));
    stimulusEnsemble.setObjectProperty('height', ...
        datatub{'FixationCue'}{'size'}.*[0.3 1], inds(1));
    stimulusEnsemble.setObjectProperty('colors', ...
        [1 0 0], inds(1));
    
    % Update gaze windows
    ui.addGazeWindow('tcWindow', ...
        'centerXY',    [x y]);
    
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
ui.flushData();
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
