function RTDconfigureGraphics(datatub)
% function RTDconfigureGraphics(datatub)
%
% RTD = Response-Time Dots
%
% Configure graphics objects, including drawables and the screen object
%
% 5/11/18 written by jig

%% ---- Screen ensemble for controlling drawing
% 
% NOTE: you can use the screen ensemble 'flip' method defined below to
% return a structure of timestamps (see dotsTheScreen.nextFrame for
% details) describing the time of drawing. Most importantly, setting up the
% ensemble in this way (using the dotsEnsembleUtilities) means that the
% flipping can be either local or remote but will return the times
% appropriate to the CPU where the flipping occurred. Here a such a command
% would be:
%   ret = callByName(datatub{'Graphics'}{'screenEnsemble'}, 'flip');

% First check for local/remote graphics
if datatub{'Input'}{'useRemote'}
   [clientIP, clientPort, serverIP, serverPort] = RTDconfigureIPs;
   remoteInfo = {true, clientIP, clientPort, serverIP, serverPort};
else
   remoteInfo = {false};
end
datatub{'Input'}{'remoteInfo'} = remoteInfo;

% Set up the screen object and ensemble
screen = dotsTheScreen.theObject();
screen.displayIndex = datatub{'Input'}{'displayIndex'};
screenEnsemble = dotsEnsembleUtilities.makeEnsemble('screenEnsemble', remoteInfo{:});
screenEnsemble.addObject(screen);
screenEnsemble.automateObjectMethod('flip', @nextFrame);

% Put 'em in the tub
datatub{'Graphics'}{'screen'} = screen;
datatub{'Graphics'}{'screenEnsemble'} = screenEnsemble;

% add start/finish fevalables to the main topsTreeNode
addCall(datatub{'Control'}{'startCallList'}, ...
   {@callObjectMethod, screenEnsemble, @open}, 'openScreen');
addCall(datatub{'Control'}{'finishCallList'}, ...
   {@callObjectMethod, screenEnsemble, @close}, 'closeScreen');

%% ---- Fixation/Target/Dots ensemble
%
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

% Two saccade targets, for dots task
%
% The saccade targets will be two circles to the left and the right of the
% stimulus/fixation cue. The separation from the center of the screen will
% be determined by a variable contained in the state object.
saccadeTargets = dotsDrawableTargets();
saccadeTargets.xCenter = datatub{'FixationCue'}{'xDVA'} + datatub{'SaccadeTarget'}{'offset'}.*[-1 1];
saccadeTargets.yCenter = datatub{'FixationCue'}{'yDVA'}.*[1 1];
saccadeTargets.nSides  = 100;
saccadeTargets.height  = [1 1] * datatub{'SaccadeTarget'}{'size'};
saccadeTargets.width   = [1 1] * datatub{'SaccadeTarget'}{'size'};

% One saccade targets, for saccade task
%
% The saccade targets will be two circles to the left and the right of the
% stimulus/fixation cue. The separation from the center of the screen will
% be determined by a variable contained in the state object.
saccadeTarget = dotsDrawableTargets();
saccadeTarget.nSides  = 100;
saccadeTarget.height  = datatub{'SaccadeTarget'}{'size'};
saccadeTarget.width   = datatub{'SaccadeTarget'}{'size'};

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

% Make and save the fixation/targets/dots ensemble for the dots task
[ensemble, inds] = RTDmakeDrawableEnsemble('dotsStimuli', ...
   {fixationCue, saccadeTargets, movingDotStim}, remoteInfo);
datatub{'Graphics'}{'dotsStimuliEnsemble'} = ensemble;
datatub{'Graphics'}{'dotsStimuli inds'} = inds;

% Make and save the fixation/target ensemble for the saccade task
[ensemble, inds] = RTDmakeDrawableEnsemble('saccadeStimuli', ...
   {fixationCue, saccadeTarget}, remoteInfo);
datatub{'Graphics'}{'saccadeStimuliEnsemble'} = ensemble;
datatub{'Graphics'}{'saccadeStimuli inds'} = inds;

%% ---- Text objects for showing instructions/feedback
%
% Make two text objects, for SAT and BIAS instructions
textA   = dotsDrawableText();
textA.y = datatub{'Text'}{'yPosition'};
textB   = dotsDrawableText();
textB.y = -datatub{'Text'}{'yPosition'};

% Make and save the ensemble
[ensemble, inds] = RTDmakeDrawableEnsemble('text', ...
   {textA, textB}, remoteInfo);
datatub{'Graphics'}{'textEnsemble'} = ensemble;
datatub{'Graphics'}{'text inds'} = inds;

