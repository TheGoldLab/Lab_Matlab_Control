% Demonstrate drawing one or more lines, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableLines(delay)

if nargin < 1
    delay = 1;
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
obj1.colors = [255 0 255];
obj1.width  = 5;
obj2 = dotsDrawableTargets();
dotsDrawable.drawFrame({obj1, obj2});
pause(delay);

% draw a fat line
l.width = 10;
l.colors = [0 0 255];
dotsDrawable.drawFrame({l});
pause(delay);

% draw many lines
n = 24;
l.xFrom = linspace(-5, 0, n);
l.xTo = linspace(0, 10, n);
l.yFrom = -5;
l.yTo = 5;
l.width = randi(5,n,1);
l.colors = lines(n*2)'.*255;
dotsDrawable.drawFrame({l});
pause(delay);

% draw antialiased lines
l.smooth = 1;
dotsDrawable.drawFrame({l});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();