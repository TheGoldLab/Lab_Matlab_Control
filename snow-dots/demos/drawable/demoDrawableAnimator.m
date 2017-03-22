% Demonstrate animation for several drawables
% @details
% This animator demo focuses on scalar values, wrapping behavior, and
% interpolated vs stepwise value changes.
%
% @ingroup dotsDemos
function demoDrawableAnimator(delay)

if nargin < 1
    delay = 10;
end

% make a flying slide show of different helicopters
helicopters = dotsDrawableImages();
helicopters.fileNames = { ...
    'helicopter-da-vinci.jpg', ...
    'helicopter-fire-fighter.jpg', ...
    'helicopter-house.jpg', ...
    'helicopter-oemichen.jpg'};
helicopters.width = 2;
helicopters.height = 2;

flyingSlideShow = dotsDrawableAnimator();
flyingSlideShow.addDrawable(helicopters);

nSlides = numel(helicopters.fileNames);
slideTimes = 0:(nSlides-1);
slideNumbers = 1:nSlides;
flyingSlideShow.addMember('slideNumber', slideTimes, slideNumbers);
flyingSlideShow.setMemberCompletionStyle('slideNumber', 'wrap', nSlides);

xTimes = [0, 4, 8];
xPoints = [-5 5 -5];
xInterpolated = true;
flyingSlideShow.addMember('x', xTimes, xPoints, xInterpolated);
flyingSlideShow.setMemberCompletionStyle('x', 'wrap', max(xTimes));

yTimes = linspace(0, 2, 20);
yPoints = 3 + sin(yTimes*2*pi/max(yTimes));
yInterpolated = true;
flyingSlideShow.addMember('y', yTimes, yPoints, yInterpolated);
flyingSlideShow.setMemberCompletionStyle('y', 'wrap', max(yTimes));

% make some spinning, rotating text
hello = dotsDrawableText();
hello.string = 'Hello, world of animation!';
hello.fontSize = 24;
hello.color = [0.8 0.2 0.2];

spinningText = dotsDrawableAnimator();
spinningText.addDrawable(hello);

spinTimes = linspace(0, 5, 40);
spinInterpolated = true;

rotationPoints = -spinTimes*360/max(spinTimes) - 90;
spinningText.addMember( ...
    'rotation', spinTimes, rotationPoints, spinInterpolated);
spinningText.setMemberCompletionStyle( ...
    'rotation', 'wrap', max(spinTimes));

xPoints = 2*cos(spinTimes*2*pi/max(spinTimes));
spinningText.addMember('x', spinTimes, xPoints, spinInterpolated);
spinningText.setMemberCompletionStyle('x', 'wrap', max(spinTimes));

yPoints = -2*sin(spinTimes*2*pi/max(spinTimes));
spinningText.addMember('y', spinTimes, yPoints, spinInterpolated);
spinningText.setMemberCompletionStyle('y', 'wrap', max(spinTimes));

% make a reversible explosion
explosion = dotsDrawableExplosion();
explodeDuration = 3;
nParticles = 500;
explosion.pixelSize = 3;
explosion.gravity = -10;
explosion.bounceDamping = [.3 .1];
explosion.colors = [1 0 0];%hot(100);
explosion.x = 0;
explosion.xRest = randn(1, nParticles);
explosion.y = 1;
explosion.yRest = -3;
explosion.tRest = explodeDuration + randn(1, nParticles);
explosion.isInternalTime = false;

reversibleExplosion =  dotsDrawableAnimator();
reversibleExplosion.addDrawable(explosion);
realTimes = [0 1 2]*explodeDuration;
explosionTimes = [0 2 0]*explodeDuration;
timeInterpolated = true;
reversibleExplosion.addMember('currentTime', ...
    realTimes, explosionTimes, timeInterpolated);
reversibleExplosion.setMemberCompletionStyle( ...
    'currentTime', 'wrap', max(realTimes));

%% aggregate objects into one ensemble
drawables = topsEnsemble('animator demo');
drawables.addObject(flyingSlideShow);
drawables.addObject(spinningText);
drawables.addObject(reversibleExplosion);

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