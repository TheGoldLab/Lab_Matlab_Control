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

stimulusDecisionTime = state{'Timing'}{'targetFixationDuration'};
decisionSaccadePause = state{'Timing'}{'pauseForTargetFixation'} ;

stimulusCenterXDVA     = state{'MovingDots'}{'xDVA'};
stimulusCenterYDVA     = state{'MovingDots'}{'yDVA'};
saccadeTargetRightXDVA = state{'SaccadeTarget'}{'rightXDVA'};
saccadeTargetRightYDVA = state{'SaccadeTarget'}{'rightYDVA'};
saccadeTargetLeftXDVA  = state{'SaccadeTarget'}{'leftXDVA'};
saccadeTargetLeftYDVA  = state{'SaccadeTarget'}{'leftYDVA'};

stimulusErrorRadius2 = state{'PupilLabs'}{'stimulusErrorRad2'};
saccadeTargetErrorRadius2 = state{'PupilLabs'}{'saccadeTargetErrorRad2'};

questFlag      = state{'Flag'}{'QUEST'};
meanRTFlag     = state{'Flag'}{'meanRT'};
coherenceFlag  = state{'Flag'}{'coherence'};
SATBIASFlag    = state{'Flag'}{'SAT/BIAS'};

ui = state{'Remote'}{'ui'};

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

% Find which part of the experiment we are on
if questFlag
    set = 'Quest';
elseif meanRTFlag
    set = 'MeanRT';
elseif coherenceFlag
    set = 'Coherence';
elseif SATBIASFlag
    set = 'SAT/BIAS';
end

% Load stimulus answer based on whether the trial is a Quest or regular.
trialCounter = state{set}{'counter'};
trials = state{set}{'trials'};
trial  = trials{trialCounter};

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
mglStartTime = mglGetSecs;
pupilLabsStartTime = ui.getTime();

% mPupilLabs.refresh();
% mglStartTime = mglGetSecs;
% pupilLabsStartTime = mPupilLabs.getTime();

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
    exceedDistanceToDots  = (stimulusCenterXDVA - x)^2 + (stimulusCenterYDVA - y)^2 > stimulusErrorRadius2;
    
    % If the subject breaks fixation, we pause briefly to allow him to
    % fixate on one of the two targets. Then, we record samples for a
    % preset duration to make sure the subject is fixating on one of the
    % two targets.
    if exceedDistanceToDots
        isFixating = false;
        
        % Record decision time
        pupilLabStimFinishTime = ui.getTime();
        stimFinishTime = mglGetSecs;
        
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
        decision = 0;
        
        % Check right target by making sure both eyes were fixated within
        % the error radius of the right target.
        x = pupilLabsSample(:,1);
        y = pupilLabsSample(:,2); 
        distanceToRightTarget = (saccadeTargetRightXDVA - x).^2 + (saccadeTargetRightYDVA - y).^2;
        if sum(distanceToRightTarget < saccadeTargetErrorRadius2)/length(distanceToRightTarget) > 0.95
            decision = 1;
        end
        
        % Check left target only if not classified as right target.
        if decision == 0
            distanceToLeftTarget  = (saccadeTargetLeftXDVA - x).^2 + (saccadeTargetLeftYDVA - y).^2;
            if sum(distanceToLeftTarget < saccadeTargetErrorRadius2)/length(distanceToLeftTarget) > 0.95
                decision = 2;
            end
        end
        
        % Classify whether decision was correct or incorrect.
        switch decision
            case 0
                response = nan;
            case 1
                response = 0;
            case 2
                response = 180;
        end
        
        if isnan(response)
            string = 'invalid';
        elseif response == trial.direction
            string = 'correct';
        else
            string = 'incorrect';
        end
        
        % Special case of SAT/BIAS speed context
        if strcmp(set,'SAT/BIAS')
            contexts = state{set}{'contexts'};
            contextCounter = state{'SAT/BIAS'}{'contextCounter'};
            if strcmp(contexts{contextCounter},'S')
                rt = stimFinishTime - mglStartTime;
                if rt > state{'MeanRT'}{'value'} %#ok<BDSCA>
                    string = 'slow';
                else 
                    string = 'intime';
                end
            end
        end
        
    end
end

%% Save response
trial.response = (response == trial.direction);
trial.mglStimStartTime = mglStartTime;
trial.eyelinkStimStartTime = pupilLabsStartTime;
trial.mglStimFinishTime = stimFinishTime;
trial.eyeLinkStimFinishTime = pupilLabStimFinishTime;
if strcmp(string,'invalid')
    trial.response = nan;
end
trials{trialCounter} = trial;
state{set}{'trials'} = trials; %#ok<NASGU>

end

