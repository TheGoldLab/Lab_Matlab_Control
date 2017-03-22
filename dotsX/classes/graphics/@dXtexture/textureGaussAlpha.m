function t_ = textureGaussAlpha(t_, varargin)
%A 2D Gaussian-shaped transparent mask.
%
% Makes a square, Gaussian transparent mask that can be blended with other
% onscreen graphics. The window color is white by default, and this can be
% modified with t_.modulateColor.
%
% The window has a transparent (alpha channel) hole in the middle, which
% fades towards opaque at the edges with a 2D Gausian shape.  The standard
% deviation of the Gaussian, in deg. vis. angle is given in t_.textureArgs.
%
% textureGaussAlpha puts one 2X8-bit GA image in t_.images, and one index
% in t_.ImageIndices (still image).

% compute gray image in GA pixels
%   let any color be poked in a drawtime
w = ceil(t_.w * t_.pixelsPerDegree);
t_.images = 255*ones(w, w, 2, 1);

% 2D gaussian window in alpha channel
sd = t_.textureArgs * t_.pixelsPerDegree;
x = (1:w)-(w/2);
gaus = normpdf(x, 0, sd);
t_.images(:,:,2,1) = 256-(256*(gaus'*gaus)/(normpdf(0, 0, sd)^2));

% no anmation
t_.imageIndices = 1;