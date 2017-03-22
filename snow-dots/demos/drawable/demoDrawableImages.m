% Demonstrate drawing an image from a file, allow visual inspection.
%
% @ingroup dotsDemos
function demoDrawableImages(delay)

if nargin < 1
    delay = 2;
end

% get a drawing window
dotsTheScreen.reset();
dotsTheScreen.openWindow();

% create an object which can read an image file for OpenGL display
%   the 'Tetons-Sunset.jpg' image is included along with this demo
im = dotsDrawableImages();
im.fileNames = {'Tetons-Sunset.jpg'};
im.prepareToDrawInWindow();

% show the image without stretching
dotsDrawable.drawFrame({im});
pause(delay);

% redraw the image with some stretching, rotating, and flipping
im.height = 10;
im.width = 1;
dotsDrawable.drawFrame({im});
pause(delay);

im.rotation = 45;
dotsDrawable.drawFrame({im});
pause(delay);

im.isFlippedHorizontal = true;
dotsDrawable.drawFrame({im});
pause(delay);

im.isFlippedVertical = true;
dotsDrawable.drawFrame({im});
pause(delay);

% use native image pixelSize to inform stretching
%   update client side properties to reflect server side textures
h = 20;
im.height = h;
im.width = h*(im.pixelWidths(1)/im.pixelHeights(1));
im.rotation = 0;
im.x = -5;
im.y = 3;
im.isFlippedVertical = false;
im.isFlippedHorizontal = false;
dotsDrawable.drawFrame({im});
pause(delay);

% close the OpenGL drawing window
dotsTheScreen.closeWindow();