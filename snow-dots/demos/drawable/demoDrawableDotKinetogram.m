% Demonstrate random dot kinetograms, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableDotKinetogram(delay)

if nargin < 1
    delay = 5;
end

gridSize = 4;

% create a kinetogram with minimal motion features
clean = dotsDrawableDotKinetogram();
clean.stencilNumber = 1;
clean.pixelSize = 6;
clean.diameter = 6;
clean.density = 100;
clean.yCenter = gridSize;
clean.xCenter = -gridSize;
clean.direction = 135;
clean.coherence = 50;

% create a kinetogram with many motion features
messy = dotsDrawableDotKinetogram();
messy.stencilNumber = 2;
messy.pixelSize = 7;
messy.diameter = 6;
messy.yCenter = gridSize;
messy.xCenter = gridSize;
messy.density = 50;
messy.direction = 45;
messy.coherence = 50;
messy.isFlickering = false;
messy.isWrapping = false;
messy.isLimitedLifetime = false;
messy.interleaving = 1;
messy.colors = [1 .2 1]';

% create a kinetogram with a *distribution* of motion directions
fancy = dotsDrawableDotKinetogram();
fancy.stencilNumber = 3;
fancy.diameter = 6;
fancy.yCenter = -gridSize;
fancy.xCenter = -gridSize;
fancy.pixelSize = 5;
fancy.density = 30;
fancy.direction = 0:359;
fancy.directionWeights = normpdf(fancy.direction, 225, 30);
fancy.coherence = 100;
fancy.colors = [1 1 0]';

% create a kinetogram with dots wandering, all together
silly = dotsDrawableDotKinetogram();
silly.stencilNumber = 4;
silly.diameter = 6;
silly.yCenter = -gridSize;
silly.xCenter = gridSize;
silly.pixelSize = 5;
silly.isSmooth = true;
silly.density = 50;
silly.direction = 315;
silly.coherence = 100;
silly.drunkenWalk = 180;
silly.isMovingAsHerd = true;
silly.interleaving = 1;
silly.colors = cool(10)';

% Aggrigate the kinetograms into one ensemble
kinetograms = topsEnsemble('kinetograms');
kinetograms.addObject(clean);
kinetograms.addObject(messy);
kinetograms.addObject(fancy);
kinetograms.addObject(silly);

% automate the task of drawing all the objects
%   the static drawFrame() takes a cell array of objects
isCell = true;
kinetograms.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

%% animate for the duration given above
try
    % get a drawing window
    %sc=dotsTheScreen.theObject;
    %sc.reset('displayIndex', 2);
    dotsTheScreen.reset('displayIndex', 0);
    dotsTheScreen.openWindow();
    
    % get the objects ready to use the window
    kinetograms.callObjectMethod(@prepareToDrawInWindow);
    
    % let the ensemble animate for a while
    kinetograms.run(delay);
    
    % close the OpenGL drawing window
    dotsTheScreen.closeWindow();
    
catch err
    dotsTheScreen.closeWindow();
    rethrow(err)
end