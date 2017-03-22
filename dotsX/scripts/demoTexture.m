% demoTexture.m
%
% demo texture animation with DotsX code
%
% On the left, reproduce modelfest stimulus #26, a circular
% gaussian bright patch with gaussian onset and offset
%   see http://vision.arc.nasa.gov/modelfest/stimuli.html
%   and http://journalofvision.org/5/9/6/article.aspx#Watson2000
%
% In the middle, do #6 from same, a Gabor patch.
%
% On the right, do #43 from same, a natural image.
%
% This demo is meant for the mono++ high-res grayscale box.  Textures will
% show up on a regular display in green and red, like some kind of crappy,
% funky fractals or somehting.

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

try
    rInit('local');

    % according to modelfest, we want 30cd/m^2 background.
    % this is 31.555% of the Johnson 115 Viewsonic's Lmax=97.5cd/m^2,
    bgLum = 0.31555;

    % modelfest textures are 256 pixels, ~7.0285 deg on our setup

    % make a white gaussian, up to twice the background luminance
    % make a dark gaussian, all the way down to black, and
    ti = rAdd('dXtexture', 3, ...
        'modelFestIndex', {26, 6, 43}, ...
        'duration',     {2000, 3000, 5000}, ...
        'x',            {-10, 0, 10}, ...
        'y',            {-5 0 5}, ...
        'visible',      true, ...
        'continuous',   true, ...
        'privateBackground', {true, false, false},	...
        'lum',          1, ...
        'bgLum',        bgLum);

    rGraphicsDraw(inf);
    rGraphicsBlank;
    rDone;

catch
    e = lasterror
    rDone;
end