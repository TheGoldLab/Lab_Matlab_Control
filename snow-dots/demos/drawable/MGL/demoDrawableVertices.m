% Demonstrate drawing vertices from OpenGL buffer objects.
%
% @ingroup dotsDemos
function demoDrawableVertices(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create a vertices object and draw it
v = dotsDrawableVertices();
dotsDrawable.drawFrame({v});
pause(delay);

% make up some actual vertices to draw
nVertices = 12;
v.colors = hsv(nVertices);
v.indices = [];
w = 8;
v.x = w/2*cos((2*pi/nVertices)*(0:nVertices-1));
v.y = w/2*sin((2*pi/nVertices)*(0:nVertices-1));
v.z = 0;

% draw points, lines, triangles, quads, polygon
v.pixelSize = 3;
for p = 0:9
    v.primitive = p;
    dotsDrawable.drawFrame({v});
    pause(delay);
end

% draw all vertices the same color
v.isColorByVertexGroup = true;
dotsDrawable.drawFrame({v});
pause(delay);

% draw with scaling, rotation, and translation
v.isColorByVertexGroup = false;
v.translation = [-1 -1 0]*w/2;
dotsDrawable.drawFrame({v});
pause(delay);

v.rotation = [0 0 90];
dotsDrawable.drawFrame({v});
pause(delay);

v.scaling = [2 2 0];
dotsDrawable.drawFrame({v});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();