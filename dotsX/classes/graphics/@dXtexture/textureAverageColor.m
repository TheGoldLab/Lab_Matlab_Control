function t_ = textureAverageColor(t_, varargin)
%A Gaussian-windowed patch for dXtexture.
%   one 2X8-bit GA image in t_.images,
%   one index in t_.ImageIndices (still image)
%
% The color used is the weighted average
% (t_.color * t_.lum) + (t_.bgColor * t_.bgLum).
%
% The Gaussian window is in the alpha channel, and has standard deviation
% (deg. vis. angle) in t_.duration.

% get mean color
t_.modulateColor = (t_.color * t_.lum) + (t_.bgColor * t_.bgLum);

% compute GA image in pixels
%   really just a white image with color poked in a drawtime
w = ceil(t_.w * t_.pixelsPerDegree);
t_.images = 255*ones(w, w, 2, 1);

% 2D gaussian spatial window in alpha channel
sd = t_.duration * t_.pixelsPerDegree;
gaus = normpdf(1:w, w/2, sd);
t_.images(:,:,2,1) = 255*(gaus'*gaus)/(normpdf(0, 0, sd)^2);

% no anmation
t_.imageIndices = 1;