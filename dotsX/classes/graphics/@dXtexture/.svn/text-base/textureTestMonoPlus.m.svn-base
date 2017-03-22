function t = testMonoPlusTexture(t, varargin)
%   8-bit RGB packed in in t.images,
%   a set of indices into those images in t.ImageIndices
%   possibly set the continuous flag in t.continuous
%   possibly set things like lum and color

% make two gradient stripes across the screen
%   On top, try to take advantage of mono++ by showing a
%   high-res, gamma corrected gradient, giving every pixel
%   its own gray value.
%
%   On bottom, show a same gradient quantized at
%   8-bit gray values.
%
%   If mono++ is working, top should look smooth and bottom
%   should have steps

%rInit('local')
[w, h]=Screen('WindowSize', rWinPtr);

hRes = round(linspace(0, 2^16-1, w));
lRes = 256*floor(hRes/256);

% use the 16-bit gamma table in dXscreen
gam = rGet('dXscreen', 1, 'gamma16bit');

img = gam(1+ [ ...
    repmat(hRes, floor(h/2), 1); ...
    repmat(lRes, floor(h/2), 1)]);

% pack most signif byte into red channel
%   MATLAB is a
t.images = zeros(h, w, 3, 1);
t.images(:,:,1,1) = uint8(floor(img/256));

% pack least signif byte into green channel
t.images(:,:,2,1) = uint8(mod(img, 256));

% t.images = 255*ones(100, 1000, 3, 1);
% t.images(50, :, 1, 1) = 1:1000;

t.imageIndices = 1;