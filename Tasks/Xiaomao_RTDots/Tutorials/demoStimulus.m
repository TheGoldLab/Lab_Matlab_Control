function demoStimulus
% function demoStimulus
% 
% This function will provide a demo of the stimulus to be presented during
% the moving dots task. The purpose of this function is to familiarize
% myself with the snow dots coding environment and to create a task that
% mimics that present in Huang et al. 2015 and Perugini et al. 2016. The
% order of visual presentation is as follows:
% 
%   1. Fixation cue
%   2. Left/right targets
%   3. Moving dots stimulus
%   4. Left/right targets (until decision)
%   5. Feedback
%
% 9/11/17    xd  wrote it

%% Open snow dots window
dotsTheScreen.reset('displayIndex', 0);
dotsTheScreen.openWindow();

%% Create fixation cue
% 
% It seems like the drawable targets are only available as regular polygon
% shapes. For the fixation cue, we want to use a cross in the center of the
% screen. This will be achieved using two thin rectangles that form a cross
% shape.

% Using a vector of parameters generates a shape for each entry of the
% vector. Make sure all vector are the same size.
fixationCue = dotsDrawableTargets();
fixationCue.xCenter = [0 0];
fixationCue.yCenter = [0 0];
fixationCue.width   = [1 0.1] * 0;
fixationCue.height  = [0.1 1] * 0;

dotsDrawable.drawFrame({fixationCue});
pause(2);

%% Create targets
%
% We will create a separate dotsDrawableTargets object to place the saccade
% targets on the left/right of the stimulus. This is because we want to use
% this same object when the moving dots are presented. We can freely
% combine this with either the fixation cue or the moving dots using a
% topsEnsemble object and use that to render the combined image.

offset = 5; % Temp placeholder for left/right offset
saccadeTargets = dotsDrawableTargets();
saccadeTargets.xCenter = [-offset offset];
saccadeTargets.yCenter = [0 0];
saccadeTargets.nSides  = 100;
saccadeTargets.height  = [0.7 0.7];
saccadeTargets.width   = [0.7 0.7];

% dotsDrawable.drawFrame({saccadeTargets});
fixationCueAndSaccadeTargets = topsEnsemble();
fixationCueAndSaccadeTargets.addObject(fixationCue);
fixationCueAndSaccadeTargets.addObject(saccadeTargets);

% This part makes it run, but I don't quite fully understand what is going
% on yet!!!
isCell = true;
fixationCueAndSaccadeTargets.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

fixationCueAndSaccadeTargets.callObjectMethod(@prepareToDrawInWindow);
fixationCueAndSaccadeTargets.run(2);

% pause(10);

%% Create moving dots and present with saccade targets
%
% Create a moving dot stimulus centered on the screen. Set its with equal
% to a temporary variable. We want to combine this in a topsEnsemble object
% with the saccade target which means that the diameter of the moving dots
% stimulus cannot be greater than the distance between the two targets.

movingDotStim = dotsDrawableDotKinetogram();
movingDotStim.stencilNumber = 1;
movingDotStim.pixelSize = 3;
movingDotStim.diameter = 5;
movingDotStim.yCenter = 0;
movingDotStim.xCenter = 0;
movingDotStim.direction = 0;
movingDotStim.coherence = 50;

stimulusAndSaccadeTargets = topsEnsemble();
stimulusAndSaccadeTargets.addObject(movingDotStim);
stimulusAndSaccadeTargets.addObject(saccadeTargets);

isCell = true;
stimulusAndSaccadeTargets.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

stimulusAndSaccadeTargets.callObjectMethod(@prepareToDrawInWindow);
stimulusAndSaccadeTargets.run(2);
 
%% Display only the blank saccade target screens
%
% In the real experiment, this would stay up until the subject responds (or
% until a predetermined amount of time has expired). However, for this
% demo, it will stay onscreen for 2 s before changing to the next frame.

dotsDrawable.drawFrame({saccadeTargets});
pause(2);

%% Display Feedback
%
% In the real experiment, the frame presented here would be dependent on
% the subject's response. Here, however, we will just show the word
% 'correct'.

feedback = dotsDrawableText();
feedback.string = 'correct';

dotsDrawable.drawFrame({feedback});
pause(2);

%% Close the stimulus screen
dotsTheScreen.closeWindow();

end

