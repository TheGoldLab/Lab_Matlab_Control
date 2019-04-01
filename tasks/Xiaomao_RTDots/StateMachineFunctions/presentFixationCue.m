function presentFixationCue(state)
% presentFixationCue(state)
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

% Duration of fixation required continue with the trial. Also the error
% allowed for the fixation from the cue location.
fixationDuration = state{'Timing'}{'fixationCueFixationDuration'};
fixationErrorRadius2 = state{'PupilLabs'}{'fixationCueErrorRad2'};

% Location of the fixation cue in pixel coordinates.
px = state{'FixationCue'}{'xDVA'};
py = state{'FixationCue'}{'yDVA'};

% Get remote ui
ui = state{'Remote'}{'ui'};

% Get the trial we are on so that we can update temporal data structure.
[trial,set,trialCounter] = getCurrentTrial(state);

%% Present fixation cue
fixationCue = state{'graphics'}{'fixationCue'};
fixationCue.callObjectMethod(@prepareToDrawInWindow);

% We use a while loop to briefly present the fixation cue. While
% presenting, we check the current location of the subject's gaze and track
% to see whether the subject has been fixating within the appropriate
% location for the desired amount of time.
samplesWithinFixation = zeros(1000,2);
sampleCounter = 1;
fixating = false;

% Record the starting time of the trial

% mPupilLabs.timeSync();
% mPupilLabs.refresh();
% mglStartTime = mglGetSecs;
% pupilLabsStartTime = mPupilLabs.getTime();
% time = pupilLabsStartTime;

ui.timeSync();
ui.refreshSocket();
mglStartTime = mglGetSecs;
pupilLabsStartTime = ui.getTime();
time = pupilLabsStartTime;

if isa(fixationCue,'dotsClientEnsemble')
    fixationCue.start();
    started = true;
else
    started = false;
end

while ~fixating
    if ~started
        fixationCue.runBriefly();
    end
    
    % Collect a sample from Eyelink. We skip the loop if it is empty (a
    % blink).
%     pupilLabsSample = mPupilLabs.getGazeData();
%     pupilLabsPos = cell2num(cell(pupilLabsSample.norm_pos));
%     pupilLabsPos = convertPupilLabsToSnowDotsCoord(pupilLabsPos);
    
    pupilLabsSample = ui.readAndReturnData();
    pupilLabsPos = pupilLabsSample(1:2,2);
    
    % Skip if time is negative or diff from last time sample is too great.
    if pupilLabsSample(1,3) < 0 || pupilLabsSample(1,3) - time > 50
        continue;
    end
    
    % Check if sample is within fixation radius of the target point.
    x = pupilLabsPos(1);
    y = pupilLabsPos(2);
    samplesWithinFixation(sampleCounter,1) = pupilLabsSample(1,3);
    samplesWithinFixation(sampleCounter,2) = (px-x(1))*(px-x(1)) + (py-y(1))*(py-y(1)) < fixationErrorRadius2;
    
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
fixationCue.finish();

%% Present fixation cue with saccade targets

% Randomly sample a duration from an exponential distribution and apply max
% cutoff.
meanFCandSTtime = state{'Timing'}{'meanFixationCueAndSaccadeTargets'};
maxFCandSTtime  = state{'Timing'}{'maxFCandST'};
FCandSTtime = min(exprnd(meanFCandSTtime), maxFCandSTtime);

% Play cue and saccade targets for that long.
fixationCueAndSaccadeTargets = state{'graphics'}{'fixationCueAndSaccadeTargets'};
fixationCueAndSaccadeTargets.callObjectMethod(@prepareToDrawInWindow);
fixationCueAndSaccadeTargets.run(FCandSTtime);

%% Update trial fields
trial.mglTrialStartTime = mglStartTime;
trial.eyelinkTrialStartTime = pupilLabsStartTime;
trial.saccadeTargetDuration = FCandSTtime;

updateCurrentTrial(state,trial,set,trialCounter);

end

