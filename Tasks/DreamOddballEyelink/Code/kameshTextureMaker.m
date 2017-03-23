function textureInfo = kameshTextureMaker( ...
    textureObject, checkH, checkW, totalH, totalW, color1, color2)
% Make a checkerboard texture of size totalH X totalW where each texture is
% checkH X checkW and the checker in the top left is color1, and the
% other checker is color2

if isempty(totalH) || isempty(totalW)
    screen = dotsTheScreen.theObject();
    totalW = screen.displayPixels(3);
    totalH = screen.displayPixels(4);
end

% fill out a simple grid which represents the checker board, plus margins
nCheckH = ceil(totalH/checkH);
nCheckW = ceil(totalW/checkW);
oddCheck = true(checkH, checkW);
evenCheck = false(checkH, checkW);
oddRow = repmat([oddCheck, evenCheck], 1, ceil(nCheckW/2));
evenRow = ~oddRow;
grid = repmat([oddRow; evenRow], ceil(nCheckH/2), 1);

% fill in a matrix of colors, based on the grid
nColors = numel(color1);
colors = zeros(totalH, totalW, nColors);
plane = zeros(totalH, totalW);
for ii = 1:nColors
    plane(grid(1:totalH, 1:totalW)) = color1(ii);
    plane(~grid(1:totalH, 1:totalW)) = color2(ii);
    colors(:,:,ii) = plane;
end

%% Make an OpenGL texture and return info about it
textureInfo = mglCreateTexture(colors);