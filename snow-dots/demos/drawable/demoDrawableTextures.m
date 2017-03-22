% Demonstrate drawing arbitrary textures, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableTextures(delay)


if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create a texture-drawing object
tx = dotsDrawableTextures();

% configure the texture object to draw a checkerboard texture with some
% colored checkers.
% The "checkerTextureMaker" function is included along with this
% demo script.  It knows how to make a checkerboard texture with
% OpenGL.  It expectes to receive the texture object and a color
% parameter.
red = [192 16 16];
tx.textureMakerFevalable = {@checkerTextureMaker, red};

% checkers should have abrupt edges, not isSmooth blending
tx.isSmooth = false;

% create a target dot to display near or behind the texture
dot = dotsDrawableTargets();
blue = [16 0 128];
dot.pixelSize = 1;
dot.colors = blue;

% add the texture and dot objects to an ensemble, to draw them together
%   order of addition is order of drawing
drawables = topsEnsemble('drawables');
drawables.addObject(dot);
drawables.addObject(tx);

% automate the task of drawing all the objects
%   the static drawFrame() takes a cell array of objects
isCell = true;
drawables.automateObjectMethod( ...
    'draw', @dotsDrawable.drawFrame, {}, [], isCell);

% draw the checkered texture at a small pixelSize
%   it will occlude the blue dot
tx.width = 1;
tx.height = 1;
drawables.callByName('draw');
pause(delay);

% draw the checkered texture at a larger pixelSize
%   it will still occlude the blue dot
tx.width = 10;
tx.height = 5;
drawables.callByName('draw');
pause(delay);

% draw the checkered texture at a larger pixelSize, and other changes
%   it will rotate and move to reveal the blue dot behind it!
tx.x = -5;
tx.rotation = 45;
tx.isSmooth = true;
drawables.callByName('draw');
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();