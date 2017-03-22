% Demonstrate drawing one or more lines, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableLines(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create a lines object
l = dotsDrawableLines();

% draw one line
l.xFrom = 0;
l.xTo = 1;
l.yFrom = 0;
l.yTo = 10;
dotsDrawable.drawFrame({l});
pause(delay);

obj1 = dotsDrawableLines();
obj2 = dotsDrawableTargets();

dotsDrawable.drawFrame({obj1, obj2});



% draw a fat line
l.pixelSize = 10;
l.colors = [1 0 0];
dotsDrawable.drawFrame({l});
pause(delay);

% draw many lines
n = 24;
l.xFrom = linspace(-5, 0, n);
l.xTo = linspace(0, 10, n);
l.yFrom = -5;
l.yTo = 5;
l.pixelSize = 2;
l.colors = lines(n);
dotsDrawable.drawFrame({l});
pause(delay);

% draw crazy colors
l.isColorByVertexGroup = false;
dotsDrawable.drawFrame({l});
pause(delay);

% draw antialiased lines
l.isSmooth = true;
dotsDrawable.drawFrame({l});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();