% Demonstrate one or more targets, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableTargets(delay)

if nargin < 1
    delay = 1;
end

% get a drawing window
%sc=dotsTheScreen.theObject;
%sc.reset('displayIndex', 2);

dotsTheScreen.reset('displayIndex', 0);
dotsTheScreen.openWindow();

% create a targets object
t = dotsDrawableTargets();

% draw two targets
t.xCenter = [-10 10];
t.yCenter = 0;
t.width   = 2;
t.targetType = 'FillOval';
dotsDrawable.drawFrame({t});
pause(delay);

% draw two elongated targets
t.xCenter = 0;
t.height = 5;
dotsDrawable.drawFrame({t});
pause(delay);

% draw many targets
n = 10;
t.xCenter = linspace(-10, 10, n)';
t.yCenter = linspace(-5, 5, n)';
t.width   = linspace(0.1, 1, n)';
t.height  = linspace(1, 0.1, n)';
t.colors  = hot(n)';
dotsDrawable.drawFrame({t});
pause(delay);

% draw some different shapes
t.targetType = 'FrameRect';
dotsDrawable.drawFrame({t});
pause(delay);

t.targetType = 'FillOval';
dotsDrawable.drawFrame({t});
pause(delay);

t.targetType = 'FrameOval';
t.colors   = [0 255 0];
t.penWidth = 3;
dotsDrawable.drawFrame({t});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();