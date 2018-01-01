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
arc.width   = 5;
arc.startAngle = -30;
arc.sweepAngle = 180;
arc.color = [0 128 64];
dotsDrawable.drawFrame({arc});
pause(delay);

% change type
arc.arcType = 'FillArc';
dotsDrawable.drawFrame({arc});
pause(delay);

arc.arcType = 'FrameArc';
arc.penWidth = 3;
arc.penHeight = 3;
dotsDrawable.drawFrame({arc});
pause(delay);

% draw several smoother arcs
n = 5;
arcs = cell(n,1);
coppermap = hot(n).*255;
for ii = 1:n
   arcs{ii} = dotsDrawableArcs();
   arcs{ii}.width  = ii;
   arcs{ii}.height = 2*ii;
   arcs{ii}.startAngle = (ii-1)*270/n;
   arcs{ii}.sweepAngle = ii*10;
   arcs{ii}.color = coppermap(ii,:);
end
dotsDrawable.drawFrame(arcs);
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();