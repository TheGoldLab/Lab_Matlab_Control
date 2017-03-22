% Demonstrate one or more targets, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableTargets(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
%sc=dotsTheScreen.theObject;
%sc.reset('displayIndex', 2);

dotsTheScreen.reset('displayIndex', 0);
dotsTheScreen.openWindow();

% create a targets object
t = dotsDrawableTargets();

% draw one target
t.isSmooth = false;
t.xCenter = 0;
t.yCenter = 0;
t.colors = [1 0 0];
t.nSides = 4;
dotsDrawable.drawFrame({t});
pause(delay);

% draw one fat target
t.height = 5;
t.width = 8;
dotsDrawable.drawFrame({t});
pause(delay);

% draw many targets
n = 10;
t.xCenter = linspace(-10, 10, n);
t.yCenter = linspace(-5, 5, n);
t.width = linspace(0.1, 1, n);
t.height = linspace(1, 0.1, n);
dotsDrawable.drawFrame({t});
pause(delay);

% draw some different polygons
t.xCenter = [-5 5];
t.yCenter = 0;
t.width = 8;
t.height = 8;
t.colors = cool(n);
t.nSides = 30;
dotsDrawable.drawFrame({t});
pause(delay);

t.nSides = 7;
dotsDrawable.drawFrame({t});
pause(delay);

% draw crazy colors
t.isColorByVertexGroup = false;
dotsDrawable.drawFrame({t});
pause(delay);

% try to isSmooth the target edges
t.isSmooth = true;
dotsDrawable.drawFrame({t});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();