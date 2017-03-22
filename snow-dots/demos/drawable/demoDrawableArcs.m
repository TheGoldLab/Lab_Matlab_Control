% Demonstrate drawing one or more circular arcs, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableArcs(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create an arcs object and add it to an arbitrary group
arc = dotsDrawableArcs();

% draw one coarse arc
arc.xCenter = 0;
arc.yCenter = 0;
arc.startAngle = -30;
arc.sweepAngle = 180;
arc.colors = [0 128 64];
arc.nPieces = 10;
dotsDrawable.drawFrame({arc});
pause(delay);

% draw one smoother arc
arc.nPieces = 100;
dotsDrawable.drawFrame({arc});
pause(delay);

% draw several smoother arcs
n = 5;
arc.xCenter = 0;
arc.yCenter = 0;
arc.startAngle = linspace(0, 270, n);
arc.sweepAngle = 20*ones(1,n);
arc.rInner = linspace(4, 8, n);
arc.rOuter = linspace(5, 10, n);
dotsDrawable.drawFrame({arc});
pause(delay);

% draw colorful arcs
arc.colors = hsv(n);
dotsDrawable.drawFrame({arc});
pause(delay);

% show some crazy colors by ignoring arc boundaries
arc.isColorByVertexGroup = false;
dotsDrawable.drawFrame({arc});
pause(delay);

% try to isSmooth out the arc edges further
arc.isSmooth = true;
dotsDrawable.drawFrame({arc});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();