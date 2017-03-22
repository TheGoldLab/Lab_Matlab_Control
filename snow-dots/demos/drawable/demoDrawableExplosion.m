% Demonstrate exploding particle systems, allow visual inspection
%
% @ingroup dotsDemos
function demoDrawableExplosion(delay)

if nargin < 1
    delay = 5;
end

% choose some parameters for all systems
meanTime = 0.5*delay;
gravity = -10;
bounceDamping = [.5 .3];
yRest = -3;
nParticles = 100;
particleSize = 3;
startVisible = false;

% create an explosive system that tosses particles frmo left to right
toss = dotsDrawableExplosion();
toss.isVisible = startVisible;
toss.pixelSize = particleSize;
toss.gravity = gravity;
toss.bounceDamping = bounceDamping;
toss.x = -5;
toss.xRest = 3 + 0.5*randn(1, nParticles);
toss.y = yRest;
toss.yRest = yRest;
toss.tRest = meanTime + randn(1, nParticles);
toss.colors = autumn(10);

% create a firework with uniform particle distributions
uniform = dotsDrawableExplosion();
uniform.isVisible = startVisible;
uniform.pixelSize = particleSize;
uniform.gravity = gravity;
uniform.bounceDamping = bounceDamping;
uniform.x = 0;
uniform.xRest = 8*(rand(1, nParticles) - 0.5);
uniform.y = 1;
uniform.yRest = yRest - (uniform.xRest > 0);
uniform.tRest = meanTime + 2*(rand(1, nParticles) - 0.5);
uniform.colors = winter(10);

% create a firework with normal particle distributions
normal = dotsDrawableExplosion();
normal.isVisible = startVisible;
normal.pixelSize = particleSize;
normal.gravity = gravity;
normal.bounceDamping = bounceDamping;
normal.x = 0;
normal.xRest = 2*randn(1, nParticles);
normal.y = 1;
normal.yRest = yRest + 0.05*(normal.xRest.^2);
normal.tRest = meanTime + randn(1, nParticles);
normal.colors = spring(10);

% create a fierce hail storm
fierce = dotsDrawableExplosion();
fierce.whichRoot = 1;
fierce.isVisible = startVisible;
fierce.pixelSize = particleSize;
fierce.gravity = gravity;
fierce.bounceDamping = bounceDamping;
fierce.x = 3;
fierce.xRest = -2*rand(1, nParticles);
fierce.y = 1;
fierce.yRest = yRest;
fierce.tRest = meanTime + randn(1, nParticles);
fierce.colors = summer(10);

% group the drawables into an ensemble
drawables = topsEnsemble('explosons');
drawables.addObject(toss);
drawables.addObject(uniform);
drawables.addObject(normal);
drawables.addObject(fierce);

% let explosions start out hidden
drawables.callObjectMethod(@hide);

% show starting and ending postions for particles, up front
origin = dotsDrawableVertices();
origin.pixelSize = particleSize;
origin.colors = [.75 .25 0];
drawables.addObject(origin);

target = dotsDrawableVertices();
target.pixelSize = particleSize;
target.colors = [0 .25 .75];
drawables.addObject(target);

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
    
    for ii = 1:4
        % preview the explosion with static targets
        explosion = drawables.getObject(ii);
        origin.x = explosion.x;
        origin.y = explosion.y;
        target.x = explosion.xRest;
        target.y = explosion.yRest;
        drawables.callByName('draw');
        pause(min(delay, 1))
        
        % reset the simulation time for each explosion, by index
        explosion.prepareToDrawInWindow();
        
        % animate each explosion for a while, by index
        explosion.show();
        drawables.run(delay);
        explosion.hide();
    end
    
    % close the OpenGL drawing window
    dotsTheScreen.closeWindow();
    
catch err
    dotsTheScreen.closeWindow();
    rethrow(err)
end