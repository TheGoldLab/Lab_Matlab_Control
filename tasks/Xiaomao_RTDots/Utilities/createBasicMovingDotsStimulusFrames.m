function createBasicMovingDotsStimulusFrames(state)
% state = createBasicMovingDotsStimulusFrames(state)
% 
% This function populates the state list with a series of topsEnsembles
% that represent each part of the stimulus. This is done under the
% 'graphics' tag. The basic frames are as follows: fixation cue, fixation
% cue + saccade targets, saccade targets, incorrect/correct feedback,
% blank.
%
% Inputs:
%   state  -  A topsGroupedList object which carries information about the
%             state of the experiment. 
%
% 9/12/17    xd  wrote it

%% Check whether we want to use a client-server set up
usingRemote = state.containsGroup('Remote');
if ~usingRemote
    ensembleFunction = @(X)topsEnsemble;
else
    clientIP = state{'Remote'}{'clientIP'};
    clientPort = state{'Remote'}{'clientPort'};
    serverIP = state{'Remote'}{'serverIP'};
    serverPort = state{'Remote'}{'serverPort'};
    ensembleFunction = @(X)dotsClientEnsemble(X,clientIP,clientPort,serverIP,serverPort);
end

%% Create the fixation cue frame
%
% Here we create a cross with two thin rectangles. Although this the
% presentation of the fixation cue only needs one frame, we will still wrap
% it in a topsEnsemble object. This makes the stimulus presentation code
% that interacts with these graphics objects much cleaner.

fixationSize = state{'FixationCue'}{'size'};

% Create a fixation cue scaled by its size parameter
fixationCue = dotsDrawableTargets();
fixationCue.xCenter = [0 0];
fixationCue.yCenter = [0 0];
fixationCue.width   = [1 0.1] * fixationSize;
fixationCue.height  = [0.1 1] * fixationSize;
fixationCue.nSides  = 4;

fixationCueE = ensembleFunction('FixationCue');
fixationCueE.addObject(fixationCue);
fixationCueE.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'fixationCue'} = fixationCueE;

%% Create saccade targets
%
% The saccade targets will be two circles to the left and the right of the
% stimulus/fixation cue. The separation from the center of the screen will
% be determined by a variable contained in the state object.

saccadeTargetoffset = state{'SaccadeTarget'}{'offset'};
saccadeTargetSize   = state{'SaccadeTarget'}{'size'};

saccadeTargets = dotsDrawableTargets();
saccadeTargets.xCenter = [-saccadeTargetoffset saccadeTargetoffset];
saccadeTargets.yCenter = [0 0];
saccadeTargets.nSides  = 100;
saccadeTargets.height  = [1 1] * saccadeTargetSize;
saccadeTargets.width   = [1 1] * saccadeTargetSize;

saccadeTargetsE = ensembleFunction('saccadeTargets');
saccadeTargetsE.addObject(saccadeTargets);
saccadeTargetsE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'saccadeTargets'} = saccadeTargetsE;
state{'graphics'}{'saccadeTargetsFrame'} = saccadeTargets;

%% Combine saccade targets and fixation cue into one ensemble

fixationCueAndSaccadeTargetsE = ensembleFunction('FixationCueAndSaccadeTargets');
fixationCueAndSaccadeTargetsE.addObject(fixationCue);
fixationCueAndSaccadeTargetsE.addObject(saccadeTargets);
fixationCueAndSaccadeTargetsE.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'fixationCueAndSaccadeTargets'} = fixationCueAndSaccadeTargetsE;

%% Create feedback frames
% 
% The feedback frames are simply two frames that display 'correct' and
% 'incorrect' in the center of the screen.

correct = dotsDrawableText();
correct.string = 'Correct';

incorrect = dotsDrawableText();
incorrect.string = 'Incorrect';

invalid = dotsDrawableText();
invalid.string = 'Invalid';

correctE = ensembleFunction('Correct');
correctE.addObject(correct);
correctE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

incorrectE = ensembleFunction('Incorrect');
incorrectE.addObject(incorrect);
incorrectE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

invalidE = ensembleFunction('Invalid');
invalidE.addObject(invalid);
invalidE.automateObjectMethod('draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'correct'} = correctE;
state{'graphics'}{'incorrect'} = incorrectE;
state{'graphics'}{'invalid'} = invalidE;

%% Create a blank frame
%
% This is a blank frame to present in between trials.
intertrial = dotsDrawableTargets();
intertrial.xCenter = 0;
intertrial.yCenter = 0;
intertrial.width   = 0;
intertrial.height  = 0;
intertrial.nSides  = 4;

intertrialE = ensembleFunction('Blank');
intertrialE.addObject(intertrial);
intertrialE.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

state{'graphics'}{'intertrialBlank'} = intertrialE;
end

