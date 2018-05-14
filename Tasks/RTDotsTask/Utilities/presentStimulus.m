function string = presentStimulus(state)
% string = presentStimulus(state)
%
% This scripts presents the moving dots stimulus on the screen. The
% stimulus will stay on the screen until the user's gaze leaves a
% predetermined area centered on the stimulus. Once the subject's gaze
% leaves, the script pauses briefly to allow for the subject to saccade to
% a target, before attempting to classify the subject's fixation onto one
% of the two fixation targets.
%
% Inputs:
%   state  -  topsGroupedList object that contains the generated stimulus
%             that is ready to be drawn. Additionally, also contains
%             parameters necessary for distinguishing whether the subject's
%             gaze has gone off the stimulus.
%
% Outputs:
%   string  -  A string determining the next state for the topsStateMachine
%              to enter. This is based on the subject's response to the
%              task.
%
% 9/16/17    xd  moved out of demoStimulusEyelink

%% Extract params from state

stimulusDecisionTime   = state{'Timing'}{'targetFixationDuration'};
decisionSaccadePause   = state{'Timing'}{'pauseForTargetFixation'} ;
stimulusCenterXDVA     = state{'MovingDots'}{'xDVA'};
stimulusCenterYDVA     = state{'MovingDots'}{'yDVA'};
saccadeTargetRightXDVA = state{'SaccadeTarget'}{'rightXDVA'};
saccadeTargetRightYDVA = state{'SaccadeTarget'}{'rightYDVA'};
saccadeTargetLeftXDVA  = state{'SaccadeTarget'}{'leftXDVA'};
saccadeTargetLeftYDVA  = state{'SaccadeTarget'}{'leftYDVA'};
stimulusErrorRadius2   = state{'PupilLabs'}{'stimulusErrorRad2'};
saccadeTargetErrorRadius2 = state{'PupilLabs'}{'saccadeTargetErrorRad2'};

% get the eye tracker object
ui = state{'Remote'}{'ui'};

% get the current trial
taskArray = state{'task'}{'taskArray'};
taskCounter = state{'task'}{'taskCounter'};
trialCounter = state{'task'}{'trialCounter'};
trial = taskArray{2, taskCounter}(trialCounter);

%% Present stimulus and detect fixations
%
% We will present the stimulus in brief intervals programmatically (will
% not be noticeable to the subject) and continously check if the subject
% has fixated on one of the two targets. Once this is detected, we will
% classify the decision as correct or incorrect and provide feedback to the
% subject.

% Prepare necessary frames for rendering.
stimulusAndSaccadeTargets = state{'graphics'}{'stimulusAndSaccadeTargets'};
stimulusAndSaccadeTargets.callObjectMethod(@prepareToDrawInWindow);
saccadeTargets = state{'graphics'}{'saccadeTargets'};
saccadeTargets.callObjectMethod(@prepareToDrawInWindow);

% Blink params. We want to keep track of the last five eyelink samples to
% tell us if the subject has blinked. However, there is also the
% possibility that the subject has closed his eyes. We account for this by
% limiting the possible number of samples that get continously classified
% as blinks. If this number of samples is exceeded, the trial is considered
% invalid.
numSamplesForBlink = 3;
refreshInterval = 75;
trueSampleCount = 1;

% Initialize loop condition
isFixating = true;

% Get time from eyelink/mgl in order to sync data later. We do this as
% close to the loop as possible to get an accurate time stamp.
ui.refreshSocket();
trial.mglStimStartTime = mglGetSecs;
trial.eyeStimStartTime = ui.getTime();

state{'Timing'}{'dotsTimeout'} = 5;


% wait until fixation or timeout
while isFixating
   if isa(stimulusAndSaccadeTargets,'dotsClientEnsemble')
      stimulusAndSaccadeTargets.start();
   else
      stimulusAndSaccadeTargets.runBriefly();
   end
   % Get new eyelink sample. We skip the first few samples so we can
   % accumulate enough to determine whether the subject has blinked. A
   % blink will be classified as when any of the eyelink samples contains
   % an empty value for x or y position.
   idx = mod(trueSampleCount,numSamplesForBlink);
   if idx == 0, idx = numSamplesForBlink; end
   
   singleSample = ui.readAndReturnData();%mPupilLabs.getGazeData();
   %     pupilLabsSample(idx,:) = convertPupilLabsToSnowDotsCoord(cell2num(cell(singleSample.norm_pos))); %#ok<AGROW>
   pupilLabsSample(idx,:) = singleSample(1:2,2)'; %#ok<AGROW>
   
   trueSampleCount = trueSampleCount + 1;
   if trueSampleCount <= numSamplesForBlink
      continue;
   end
   
   if mod(trueSampleCount,refreshInterval) == 0
      ui.refreshSocket();
   end
   
   % We use the mean of the stored samples to determine whether the
   % subject is fixating within the stimulus. The mean is used because
   % Eyelink detects a shift in y-position whenever a blink event occurs.
   % The mean effectively reduces this shift (since we do not want to
   % classify a blink as a fixation break).
   
   x = mean(pupilLabsSample(:,1));
   y = mean(pupilLabsSample(:,2));
   isFixating  = (stimulusCenterXDVA - x)^2 + (stimulusCenterYDVA - y)^2 <= stimulusErrorRadius2;
end

% If the subject breaks fixation, we pause briefly to allow him to
% fixate on one of the two targets. Then, we record samples for a
% preset duration to make sure the subject is fixating on one of the
% two targets.

% Record saccade onset (decision) time
trial.mglStimFinishTime = mglGetSecs;
trial.eyeStimFinishTime = ui.getTime();

% Present only saccade targets at this point!
stimulusAndSaccadeTargets.finish();
saccadeTargets.run(decisionSaccadePause);

% Pause briefly to allow for subject to saccade
%         pause(decisionSaccadePause);
ui.refreshSocket();

% Check for fixation on one of the two targets by recording until
% the desired amount of time has passed.
collectData = true;
collectStartTime = ui.getTime();
stopTime = collectStartTime + stimulusDecisionTime;

pupilLabsSample = zeros(1,2);
while collectData
   singleSample = ui.readAndReturnData();%mPupilLabs.getGazeData();
   pupilLabsSample(end+1,:) = singleSample(1:2,2)'; %#ok<AGROW>
   if singleSample(1,3) > stopTime
      collectData = false;
   end
end
trial.choice = nan;

% Check right target by making sure both eyes were fixated within
% the error radius of the right target.
x = pupilLabsSample(:,1);
y = pupilLabsSample(:,2);
if sum((saccadeTargetRightXDVA - x).^2 + (saccadeTargetRightYDVA - y).^2 < ...
      saccadeTargetErrorRadius2)/length(distanceToRightTarget) > 0.95
   trial.choice = 0;
elseif sum((saccadeTargetLeftXDVA  - x).^2 + (saccadeTargetLeftYDVA  - y).^2 < ...
      saccadeTargetErrorRadius2)/length(distanceToLeftTarget) > 0.95
   trial.choice = 180;
end

% save correct, RT
trial.correct = trial.choice==trial.direcetion;
trial.RT      = trial.mglStimFinishTime - trial.mglStimStartTime;
%% save trial
taskArray{2, taskCounter}(trialCounter) = trial;
state{'task'}{'taskArray'} = taskArray;

end

