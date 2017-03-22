% Demonstrate more animation for several drawables.
% @details
% This animator demo focuses on:
%   - matrix-sized values
%   - drift and stop behavior for animated values
%   - animating with a method instead of a property
%   - animating more than one drawable with the same animator
%   - choosing whether an animator should invoke draw() on its drawables
%   - sorting drawables and animators for layering
%   .
%
% @ingroup dotsDemos
function demoDrawableAnimator2(delay)

if nargin < 1
    delay = 10;
end

launchDuration = 0.5*delay;
padLevel = -3;
towerHeight = 3;

% make a rocket that shakes as it accelerates upward
rocket = dotsDrawableImages();
rocket.fileNames = {'rocket-blue-ninja.tif'};
rocket.isSmooth = true;
rocket.width = 2.5;
rocket.height = 3;

launchingRocket = dotsDrawableAnimator();
launchingRocket.addDrawable(rocket);

timePoints = linspace(0, launchDuration, 25);
yPoints = padLevel + rocket.height/2 ...
    + towerHeight*(timePoints.^4)/(timePoints(end).^4);
finalSpeed = ...
    (yPoints(end)-yPoints(end-1)) / (timePoints(end)-timePoints(end-1));
launchingRocket.addMember('y', timePoints, yPoints, true);
launchingRocket.setMemberCompletionStyle('y', 'drift', finalSpeed);

jitterPoints = [0.1, 0];
timePoints = [0 launchDuration];
launchingRocket.addMember(@jitteryX, timePoints, jitterPoints, true);
launchingRocket.setMemberCompletionStyle(@jitteryX, 'stop');

% make an explosion like fire coming out of the rocket!
fire = dotsDrawableExplosion();
nParticles = 5000;
exhaustDuration = 10;
fire.x = 0;
fire.xRest = 0.1*randn(1, nParticles);
fire.y = padLevel + 0.1;
fire.yRest = padLevel;
fire.tRest = 0.75*exhaustDuration*rand(1, nParticles);
fire.gravity = -1;
fire.bounceDamping = [2 .9];
fire.whichRoot = 1;
fire.colors = autumn(100);
fire.pixelSize = 5;
fire.isInternalTime = false;

smoke = dotsDrawableExplosion();
smoke.x = 0;
leftOrRight = (rand(1, nParticles) > 0.5) - 0.5;
billows = (randn(1, nParticles)/5) + leftOrRight;
smoke.xRest = 5*billows;
smoke.y = padLevel + 0.1;
smoke.yRest = padLevel;
smoke.tRest = exhaustDuration*rand(1, nParticles);
smoke.gravity = -3;
smoke.bounceDamping = [0.7 1];
smoke.whichRoot = 2;
cols = zeros(100, 4);
cols(:,1:3) = bone(100);
cols(:,4) = 0.05;
smoke.colors = cols;
smoke.pixelSize = 20;
smoke.isInternalTime = false;

longExplosion = dotsDrawableAnimator();
longExplosion.addDrawable(fire);
longExplosion.addDrawable(smoke);
longExplosion.isAggregateDraw = false;
realTimes = linspace(0, launchDuration, 25);
internalTimes = linspace(0, exhaustDuration, 25);
squareTimes = (internalTimes.^2)./internalTimes(end);
longExplosion.addMember('currentTime', realTimes, squareTimes, true);
longExplosion.setMemberCompletionStyle('currentTime', 'stop');

% make a launch pad and tower which become red hot, then cool off
pad = dotsDrawableLines();
pad.yFrom = padLevel;
pad.yTo = padLevel;
pad.xFrom = -4;
pad.xTo = 4;
pad.pixelSize = 10;

tower = dotsDrawableLines();
tower.yFrom = padLevel;
tower.yTo = padLevel + towerHeight;
tower.xFrom = -1;
tower.xTo = -1;
tower.pixelSize = 5;

hotMetal = dotsDrawableAnimator();
hotMetal.addDrawable(pad);
hotMetal.addDrawable(tower);

timePoints = [0 1 1.5]*launchDuration;
chilledSteel = [0.1 0.1 0.2];
redHot = [0.8 0.6 0.4];
colorPoints = {chilledSteel, redHot, chilledSteel};
hotMetal.addMember('colors', timePoints, colorPoints, true);
hotMetal.setMemberCompletionStyle('colors', 'stop');

% Aggregate objects into a single ensemble
drawables = topsEnsemble('drawables');
drawables.addObject(longExplosion);
drawables.addObject(fire);
drawables.addObject(launchingRocket);
drawables.addObject(smoke);
drawables.addObject(hotMetal);


% automate the task of drawing all the objects
%   the static drawFrame() takes a cell array of objects
isCell = true;
drawables.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

%% animate for the duration given above
try
    % get a drawing window
    dotsTheScreen.reset();
    dotsTheScreen.openWindow();
    
    % get the objects ready to use the window
    drawables.callObjectMethod(@prepareToDrawInWindow);
    
    % let the ensemble animate for a while
    drawables.run(delay);
    
    % close the OpenGL drawing window
    dotsTheScreen.closeWindow();
    
catch err
    dotsTheScreen.closeWindow();
    rethrow(err)
end

% a "method" to randomly jitter the rocket's x-position
function jitteryX(rocket, magnitude)
rocket.x = magnitude*(rand()-0.5);
