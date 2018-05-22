function createGraphicsObjects(state)
% state = createGraphicsObjects(state)
% 
% This function populates the state list with a series of topsEnsembles
% that represent each part of the stimulus. This is done under the
% 'graphics' tag. The basic frames are as follows: fixation cue, fixation
% cue + saccade targets, saccade targets, incorrect/correct feedback,
% blank.
%
% Note that we add the screen object to each drawable ensemble. This makes
%  drawing easy but prevents us from using them in combinations.
%
% Inputs:
%   state  -  A topsGroupedList object which carries information about the
%             state of the experiment. 
%
% 4/25/18    jig updated it to include instruction cues
% 9/12/17    xd  wrote it

%-------
%% Check whether we want to use a client-server set up and make arg list
remoteInfo = state{'Inputs'}{'remoteInfo'};

%-------
%% Make screen ensemble from the screen object
screenEnsemble = dotsEnsembleUtilities.makeEnsemble('screenEnsemble', remoteInfo{:});
screen = dotsTheScreen.theObject();
screen.displayIndex = 0;
screenEnsemble.addObject(screen);
screenEnsemble.automateObjectMethod('flip', @nextFrame);
state{'graphics'}{'screen'} = screen;
state{'graphics'}{'screenEnsemble'} = screenEnsemble;

% Blank
% screenBlankEnsemble = dotsEnsembleUtilities.makeEnsemble('screenBlank', remoteInfo{:});
% screenBlankEnsemble.addObject(screen);
% screenBlankEnsemble.automateObjectMethod('blank', @blank);
% state{'graphics'}{'screenBlankEnsemble'} = screenBlankEnsemble;

%-------
%% Ensemble of task stimuli, automate the task of drawing objects
%

% Fixation cue
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
state{'graphics'}{'fixationCue'} = fixationCue;

% Saccade targets
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
state{'graphics'}{'saccadeTargets'} = saccadeTargets;

% Dots stimulus
movingDotStim = dotsDrawableDotKinetogram();
movingDotStim.stencilNumber = state{'MovingDots'}{'stencilNumber'};
movingDotStim.pixelSize = state{'MovingDots'}{'pixelSize'};
movingDotStim.diameter = state{'MovingDots'}{'diameter'};
movingDotStim.density = state{'MovingDots'}{'density'};
movingDotStim.speed = state{'MovingDots'}{'speed'};
movingDotStim.yCenter = 0;
movingDotStim.xCenter = 0;
state{'graphics'}{'movingDotsStimulus'} = movingDotStim;

% Make and save the ensemble
[ensemble, inds] = RTDmakeDrawableEnsemble('instructions', ...
   {fixationCue, saccadeTargets, movingDotStim}, remoteInfo);
state{'graphics'}{'fixationCue ind'} = inds(1);
state{'graphics'}{'saccadeTargets ind'} = inds(2);
state{'graphics'}{'movingDotsStimulus ind'} = inds(3);
state{'graphics'}{'stimulusEnsemble'} = ensemble;

% Make a concurrentComposite with the screenFlip ensemble
% stimulusScreenComposite = topsConcurrentComposite('stimuliScreenComposite');
% stimulusScreenComposite.addChild(stimulusEnsemble);
% stimulusScreenComposite.addChild(screenFlipEnsemble);
% screenFlipEnsemble.alwaysRunning=false; % will only runBriefly at first
% state{'graphics'}{'stimulusScreenComposite'} = stimulusScreenComposite;

%-------
%% Ensemble of SAT/BIAS instructions
%
SATtext = dotsDrawableText();
SATtext.y = 5;
state{'graphics'}{'SATtext'} = SATtext;
state{'graphics'}{'SATstrings'}  = { ...
   'S' 'Be as fast as possible'; ...
   'A' 'Be as accurate as possible'; ...
   'N' 'Be as fast and accurate as possible'; ...
   'X' ''}; 

BIAStext = dotsDrawableText();
BIAStext.y = -5;
state{'graphics'}{'BIAStext'} = BIAStext;
state{'graphics'}{'BIASstrings'}  = { ...
   'L' 'LEFT is more likely'; ...
   'R' 'RIGHT is more likely'; ...
   'N' 'BOTH directions equally likely'; ...
   'X' ''}; 

% Make and save the ensemble and composite
[ensemble, inds, composite] = RTDmakeDrawableEnsemble('instructions', ...
   {SATtext, BIAStext}, remoteInfo, screenEnsemble, false);
state{'graphics'}{'SATtext ind'} = inds(1);
state{'graphics'}{'BIAStext ind'} = inds(2);
state{'graphics'}{'instructionsEnsemble'} = ensemble;
state{'graphics'}{'instructionsScreenComposite'} = composite;

%% Feedback strings
% 
% Make a text object, see presentFeedback for more details
feedbackText = dotsDrawableText();

% Make and save the ensemble and composite
[ensemble, inds, composite] = RTDmakeDrawableEnsemble('feedback', ...
   {feedbackText}, remoteInfo, screenEnsemble, false);
state{'graphics'}{'feedbackText ind'} = inds;
state{'graphics'}{'feedbackEnsemble'} = ensemble;
state{'graphics'}{'feedbackScreenComposite'} = composite;

end

