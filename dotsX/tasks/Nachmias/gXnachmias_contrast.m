function contrast_ = gXnachmias_contrast

% central fixation, a contrast Gaussian, and an indicator ring around the
% Gaussian

% Roughly reproduce modelfest stimulus #26, a circular gaussian bright
% patch with gaussian onset and offset
%   see http://vision.arc.nasa.gov/modelfest/stimuli.html

% according to modelfest, we want 30cd/m^2 background.
% this is 31.555% of the Johnson 115 Viewsonic's Lmax=97.5cd/m^2,
% bgLum = 0.31555;

% According to modelfest data, a Gaussian contrast stimulus has its 82%
% correct threshold at -log10("Contrast") = ~1.2.
%	(see http://vision.arc.nasa.gov/modelfest/data.html)
% So, "Contrast" = .063.
%C = .063;

% pick a bright-dark-symmetric range of lower contrasts.
%nLum = 12;
%CLin = linspace(-C, 0, nLum/2);
%CLin = [CLin, -fliplr(CLin)];

% Assuming Lmin = bgLum, What is Lmax?  It depends
% on the form of "Contrast":

% If Webber Fraction, Lmax = (W+1)*Lmin,
%   Webber makes sense because there is a definite, dominatinf background
%   to compare to.  But there are no sharp edges.
%Lweb = (CLin+1).*bgLum;

% If Michelson Contrast, Lmax = ((M+1)*Lmin))/(1-M)
%   Michelson also makes sense because the thing is a smooth texture.
%   But there is not a screen-wide spatial frequency texture
%   M. generates larger/easier contrasts than Webber in this case
%Lmic = ((CLin+1).*bgLum)./(1-CLin);

% compare Weber to Michelson
% plot(CLin, Lweb, CLin, Lmic);xlabel('contrast'); ylabel('lum fraction')

% Aha, neither of those.  I finally found the 2005 Journal of Vision paper
% by Watson and Ahumada that has more details as well as more data:
%       http://journalofvision.org/5/9/6/article.aspx
%   They define contrast as:
%       L(g) = L0 * (1+ c/127 * (g-128))
%   where L(g) is the luminance at a given pixel, L0 is the mean/background
%   luminance, g is a 256x256 8-bit gray image, and c scales the mapping of
%   gray values in g to CRT luminances!
%
%   Furthermore, this paper comes with data for 16 subjects.  Their mean
%   -log10(c) = 1.6364, so mean c = 0.023099, at "threshold" for stimulus
%   #26.  This paper does not explicitly define threshold.  I assume it
%   means 82% correct, as elsewhere in modelfest.
cth = 0.023099;

% So, dXtexture should know about that contrast function and know where to
% find the modelfest gray image.  Here, we only need to pick a background
% luminance, and several values of c:

% We want 30cd/m^2 background, which is 31.555% of the Johnson 115
% Viewsonic's Lmax=97.5cd/m^2.
bgLum = 0.31555;

% to roughly match dots stimulus strength, 
% pick log spaced contrasts, mostly sub threshold
c = [0, cth*2.^(-3:1)];
c = [-fliplr(c), c];

% give central FPs the same contrast as the strongest stimulus
%   give the indicator ring twice that contrast
FPLums = bgLum*[1 1 2].*(1+c([end, 1, end]));

stimD = 5;
arg_dXtexture = { ...
    'contrast',     num2cell(c), ...
    'bgLum',        bgLum, ...
    'privateBackground', false,	...
    'textureStyle', 'monoCircleGauss', ...
    'duration',     200, ...
    'continuous',   false, ...
    'x',            0, ...
    'y',            0, ...
    'w',            stimD, ...
    'sourceRect',   [], ...
    'rotation',     0, ...
    'preload',      true};

arg_dXfunctionCaller = { ...
    'function',     {@rGraphicsShow, @rSet}, ...
    'class',        'dXtexture', ...
    'indices',      {1, []}, ...
    'args',         {{}, {'imageIndex', 1}}, ...
    'doEndTrial',   {false, true}};

% targets 1 and 2 act like a black and white donut.  target 2 penwidth is
% supposed to make equal areas of black and white.
arg_dXtarget = { ...
    'x',            0, ...
    'y',            0, ...
    'penWidth',     {1,1.0722,1}, ...
    'diameter',     {.4, .4, .5+sqrt(2)*stimD}, ...
    'color',        num2cell(FPLums), ...
    'cmd',          {0,1,1}};

tony = {'current', true, true, false};
contrast_ = { ...
    'dXtexture',	length(c),tony,	arg_dXtexture; ...
    'dXfunctionCaller', 2,  tony,	arg_dXfunctionCaller; ...
    'dXtarget',     3,      tony,	arg_dXtarget};