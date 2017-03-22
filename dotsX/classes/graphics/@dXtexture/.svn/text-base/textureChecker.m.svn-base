function t = textureChecker(t, varargin)
%   8-bit RGB packed in in t.images,
%   a set of indices into those images in t.ImageIndices
%   possibly set the continuous flag in t.continuous
%   possibly set things like lum and color

% make a gray checkerboard with variable rows, columns, colors
%   don't expect mono++, use duplicate RGB

% should be integers
varargin
rows = varargin{1};
cols = varargin{2};

% grayscale image
nc = length(t.color);
t.images = zeros(rows, cols, nc, 1);

r = logical(mod(1:cols,2));
grid = repmat([r;~r], floor(rows/2),1);

% if odd number of rows, add a row
if mod(rows,2)
    grid(rows, :) = r;
end

% poke in colors
if nc == 1
    t.images(grid) = t.color;
    t.images(~grid) = t.bgColor;
else
    cgrid = zeros(rows, cols);
    for cc = 1:nc
        cgrid(grid) = t.color(cc);
        cgrid(~grid) = t.bgColor(cc);
        t.images(:,:,cc,1) = cgrid;
    end
end

% no anmation
t.imageIndices = 1;