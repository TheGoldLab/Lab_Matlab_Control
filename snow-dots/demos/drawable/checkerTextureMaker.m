% Make a two-by-two checkerboard texture with the given RGB color.
% @param textureObject a dotsDrawableTexture object that will use the new
% texture
% @param color 1x3 RGB or 1x4 RGBA color for the texture, in [0-255]
% @details
% Creates an OpenGL texture with four checkers.  Returns a struct with
% information about the texture.
function textureInfo = checkerTextureMaker(textureObject, color)

% a 2x2 pixel image which the graphics card may stretch to any size.
image = 255*ones(2,2,4);
for ii = 1:length(color)
    image(1,1,ii) = color(ii);
    image(2,2,ii) = color(ii);
end
textureInfo = mglCreateTexture(image);