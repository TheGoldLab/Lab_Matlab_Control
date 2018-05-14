function RTDconfigureGraphics(datatub)
% function RTDconfigureGraphics(datatub)
%
% RTD = Response-Time Dots
%
% Configure graphics objects, including drawables and the screen object
%
% 5/11/18 written by jig

%% ---- Screen ensemble for controlling drawing
remoteInfo = datatub{'Input'}{'remoteInfo'};
screen = dotsTheScreen.theObject();
screen.displayIndex = datatub{'Input'}{'displayIndex'};
screenEnsemble = dotsEnsembleUtilities.makeEnsemble('screenEnsemble', remoteInfo{:});
screenEnsemble.addObject(screen);
screenEnsemble.automateObjectMethod('flip', @nextFrame);

% Put 'em in the tub
datatub{'Graphics'}{'screen'} = screen;
datatub{'Graphics'}{'screenEnsemble'} = screenEnsemble;

%% ---- Fixation/Target/Dots ensemble

% Fixation cue
%
% Here we create a cross with two thin rectangles. Although this the
% presentation of the fixation cue only needs one frame, we will still wrap
% it in a topsEnsemble object. This makes the stimulus presentation code
% that interacts with these graphics objects much cleaner.
fixationCue = dotsDrawableTargets();
fixationCue.xCenter = datatub{'FixationCue'}{'xDVA'}.*[1 1];
fixationCue.yCenter = datatub{'FixationCue'}{'yDVA'}.*[1 1];
fixationCue.width   = datatub{'FixationCue'}{'size'}.*[1 0.1];
fixationCue.height  = datatub{'FixationCue'}{'size'}.*[0.1 1];
fixationCue.nSides  = 4;
datatub{'Graphics'}{'fixationCue'} = fixationCue;

% Saccade targets
%
% The saccade targets will be two circles to the left and the right of the
% stimulus/fixation cue. The separation from the center of the screen will
% be determined by a variable contained in the state object.
saccadeTargets = dotsDrawableTargets();
saccadeTargets.xCenter = datatub{'FixationCue'}{'xDVA'} + datatub{'SaccadeTarget'}{'offset'}.*[-1 1];
saccadeTargets.yCenter = datatub{'FixationCue'}{'xDVA'}.*[1 1];
saccadeTargets.nSides  = 100;
saccadeTargets.height  = [1 1] * datatub{'SaccadeTarget'}{'size'};
saccadeTargets.width   = [1 1] * datatub{'SaccadeTarget'}{'size'};
datatub{'Graphics'}{'saccadeTargets'} = saccadeTargets;

% Dots stimulus
%
movingDotStim = dotsDrawableDotKinetogram();
movingDotStim.stencilNumber = datatub{'MovingDots'}{'stencilNumber'};
movingDotStim.pixelSize = datatub{'MovingDots'}{'pixelSize'};
movingDotStim.diameter = datatub{'MovingDots'}{'diameter'};
movingDotStim.density = datatub{'MovingDots'}{'density'};
movingDotStim.speed = datatub{'MovingDots'}{'speed'};
movingDotStim.xCenter = datatub{'MovingDots'}{'xDVA'};
movingDotStim.yCenter = datatub{'MovingDots'}{'yDVA'};
datatub{'Graphics'}{'movingDotsStimulus'} = movingDotStim;

% Make and save the fixation/targets/dots ensemble
[ensemble, inds] = RTDmakeDrawableEnsemble('stimulus', ...
   {fixationCue, saccadeTargets, movingDotStim}, remoteInfo);
datatub{'Graphics'}{'stimulus inds'} = inds;
datatub{'Graphics'}{'stimulusEnsemble'} = ensemble;

%% ---- SAT/BIAS instructions
%
% Make two text objects, for SAT and BIAS instructions
SATtext = dotsDrawableText();
SATtext.y = datatub{'Text'}{'yPosition'};
BIAStext = dotsDrawableText();
BIAStext.y = -datatub{'Text'}{'yPosition'};

% Make and save the ensemble
[ensemble, inds] = RTDmakeDrawableEnsemble('instructions', ...
   {SATtext, BIAStext}, remoteInfo);
datatub{'Graphics'}{'instruction inds'} = inds;
datatub{'Graphics'}{'instructionsEnsemble'} = ensemble;

%% ---- Feedback strings
% 
% Make a text object, see RTDsetChoice for more details
feedbackText = dotsDrawableText();

% Make and save the ensemble
[ensemble, ind] = RTDmakeDrawableEnsemble('feedback', ...
   {feedbackText}, remoteInfo);
datatub{'Graphics'}{'feedbackText ind'} = ind;
datatub{'Graphics'}{'feedbackEnsemble'} = ensemble;
