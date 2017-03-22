function t_ = textureGabor(t_, varargin)
%A Gaussian-windowed cosinusoid patch for dXtexture.
%   Makes one 2X8-bit GA image in t_.images,
%   and one index in t_.ImageIndices (still image)
%
% Makes a cosine grating with spatial frequency (cycles per deg. vis.
% angle) given in t_.textureArgs, and contrast (Michelson) in t_.contrast.
%
% The Gaussian window is in the alpha channel, and has standard deviation
% (deg. vis. angle) in t_.duration.
%
% The color used is the weighted average
% (t_.color * t_.lum) + (t_.bgColor * t_.bgLum).

% get mean color
t_.modulateColor = (t_.color * t_.lum) + (t_.bgColor * t_.bgLum);

% compute gray image in GA pixels
%   let any color be poked in a drawtime
w = ceil(t_.w * t_.pixelsPerDegree);
t_.images = 255*ones(w, w, 2, 1);

% based on the specified contrast, and some background,
%   compute the half-width of the cosinusoid
c = t_.contrast;
bg = 128;
hw = bg*[([1+c]/[1-c])-1]/[([1+c]/[1-c])+1];

% copy identical rows of cosinusoid
x = linspace(-w/2, w/2, w);
row = bg + hw*cos(x*t_.textureArgs/(2*pi));
for ii = 1:w
    t_.images(ii,:,1) = row;
end

% 2D gaussian spatial window in alpha channel
sd = t_.duration * t_.pixelsPerDegree;
gaus = normpdf(x, 0, sd);
t_.images(:,:,2,1) = 255*(gaus'*gaus)/(normpdf(0, 0, sd)^2);

% no anmation
t_.imageIndices = 1;