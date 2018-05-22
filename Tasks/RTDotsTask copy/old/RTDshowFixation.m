function nextState = RTDshowFixation(state)
% nextState = RTDshowFixation(state)
%
% This function presents the fixation cue as well as the fixation cue with
% targets. The fixation cue will be presented until the subject fixates
% within a certain radius of the cue for a pre-specified duration of time.
% Then, the fixation cue and saccade targets will be presented together for
% a random amount of time, drawn from an exponential distribution with a
% prespecified mean and max cutoff.
%
% Inputs:
%   state  -  topsGroupedList object that contains all the parameters
%             described above as well as snow dots drawable objects for the
%             fixation cue and saccade targets.
%
% 9/16/17    xd  wrote it

%% Extract parameters

% Location of the fixation cue in pixel coordinates.
px = state{'FixationCue'}{'xDVA'};
py = state{'FixationCue'}{'yDVA'};

% get current trial
taskArray = state{'task'}{'taskArray'};
taskCounter = state{'task'}{'taskCounter'};
trialCounter = state{'task'}{'trialCounter'};
trial = taskArray{2, taskCounter}(trialCounter);

%% Conditionally send TTL pulses with info about task, trial counters
sendTTLs = state{'Inputs'}{'sentTTLs'};

%% Get the screen
screen = state{'graphics'}{'screen'};

%% Get the stimulus ensemble, turn on fixation point only
stimulusEnsemble = state{'graphics'}{'stimulusEnsemble'};
   
% Set visible flags
stimulusEnsemble.setObjectProperty('isVisible', true,  ...
   state{'graphics'}{'fixationCue ind'});
stimulusEnsemble.setObjectProperty('isVisible', false, ...
   state{'graphics'}{'saccadeTargets ind'});
stimulusEnsemble.setObjectProperty('isVisible', false, ...
   state{'graphics'}{'movingDotsStimulus ind'});

%% Get ui controller, possibly refresh eye data source
ui = state{'input'}{'controller'};
if isa(ui, 'dotsReadableEyePupilLabs')
   ui.timeSync();
   ui.refreshSocket();
   
   % Only check for fixation if we have eye tracking
   samplesWithinFixation = zeros(1000,2);
   sampleCounter = 1;
   fixating = false;
   fixationErrorRadius2 = state{'PupilLabs'}{'fixationCueErrorRad2'};
else
   fixating = true;
end

%% Show the fixation point
stimuli.runBriefly();
screen.runBriefly();

% Record the starting time of the trial
trial.mglStartTime = mglGetSecs;
trial.eyeStartTime = ui.currentTime();
if sendTTLs
   trial.TTLStartTrialTime = sendTTLPulses(1, timeBetweenTTLPulses);
end
time = trial.eyeStartTime;
timeout = trial.mglStartTime + state{'Timing'}{'fixationTimeout'};

while ~fixating && mglGetSecs<timeout
      
   % Collect a sample from Pupil labs.
   pupilLabsSample = ui.readAndReturnData();
   
   % Skip if time is negative or diff from last time sample is too great.
   if pupilLabsSample(1,3) < 0 || pupilLabsSample(1,3) - time > 50
      continue;
   end
   
   % Check if sample is within fixation radius of the target point.
   x = pupilLabsSample(1,2);
   y = pupilLabsSample(2,2);
   samplesWithinFixation(sampleCounter,1) = pupilLabsSample(1,3);
   samplesWithinFixation(sampleCounter,2) = ((px-x(1))^2 + (py-y(1))^2) < fixationErrorRadius2;
   
   % Check to see if fixation occurred at cue for desired amount of time.
   % We do this by finding the latest sample that is at least the minimum
   % fixation duration away from the sample just drawn. If all samples
   % between these two points are within the fixation radius, we consider
   % the subject to be fixating on the target.
   if pupilLabsSample(1,3) - pupilLabsStartTime > fixationDuration
      times = samplesWithinFixation(:,1);
      time = samplesWithinFixation(sampleCounter,1);
      startIdx = find(times(1:sampleCounter,1) <= (time - fixationDuration),1,'last');
      if ~isempty(startIdx)
         if sum(samplesWithinFixation(startIdx:sampleCounter,2)) / length(startIdx:sampleCounter) > 0.95
            fixating = true;
         end
      end
   end
   
   % Increment sample counter
   sampleCounter = sampleCounter + 1;   
end

%% Check for fixation
if fixating
   
   % Present fixation cue with saccade targets
   
   % Randomly sample a duration from an exponential distribution with bounds
   targetForeperiod = state{'Timing'}{'minTargetForeperiod'} + ...
      min(exprnd(state{'Timing'}{'meanTargetForeperiod'}), ...
      state{'Timing'}{'maxTargetForeperiod'});
   
   % Show cue and saccade targets for that long.
   stimuli.setObjectProperty('isVisible', true, targetsInd);
   trial.mglTargetOnTime = mglGetSecs;
   
   stimuli.runBriefly();
   screen.runBriefly();
   
   pause(targetForeperiod);
   
   % next show the stimulus
   nextState = 'presentStimulus';
   
else
      
   % didn't attain fixation, finish trial
   nextState = 'updateStatus';
end

%% save trial
trial
taskArray{2, taskCounter}(trialCounter) = trial;
state{'task'}{'taskArray'} = taskArray;

end

