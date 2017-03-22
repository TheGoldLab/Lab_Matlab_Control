function t = monoCircleGaussTexture(t, varargin)
%Make an animated circular gaussian luminance patch
%
%   8-bit RGB packed in in t.images,
%   a set of indices into those images in t.ImageIndices
%   possibly set the continuous flag in t.continuous
%   possibly set things like lum and color

% Generalized from modelfest stimuli #26-29, circular
% gaussian bright patches with gaussian onset and offset
%   see http://vision.arc.nasa.gov/modelfest/stimuli.html
%   and http://journalofvision.org/5/9/6/article.aspx

% May be any witdth, not just 256 pixels, squared.
%   This is better than trying to scale modelFest images.
%   This texture will have double values, not just byte
%   values, so it's higher res than modelfest.

% get texture half-width in pixels
HPIX = ceil(t.pixelsPerDegree*t.w/2);

% make a 2D circular Gaussian
%   centered in texture (MU = 0)
%   As BSH understands, modelfest patch #26 is 128 deg min
%   wide with spatial standard deviation of 30 deg min.
%   BSH generalizes to say that the patch width corresponds
%   to 128/30~=4.2667 standard deviations. Compare:
%   #26 SD = 30 min     -> w = 4.2667 standard deviations
%   #27 SD = 8.43 min   -> w = 15.184 standard deviations
%   #28 SD = 2.106 min  -> w = 60.779 standard deviations
%   #29 SD = 1.05 min   -> w = 121.90 standard deviations

% compute gaussian with no loops (~1-20ms for 101-501 pix)
%   gaussian will have exactly 4 central maxima.
%   f(center) = 255; f(edge) > f(corner) ~= 128
DIV = -2*((HPIX*2)/(128/30))^2;
x = [HPIX-1:-1:0, 0:HPIX-1];
fx = exp((x.^2)./DIV);
ff = (fx'*fx)*127 + 128;

% how many animation textures in all?
%   gaussian goes up and down, so need half as many textures
if t.duration > 0
    nt = floor(t.frameRate/1000*t.duration/2) + 1;

    % generate gaussian-spaced contrasts in [0, t.contrast]
    DIV = -(2*(t.duration/4)^2);
    cGaus = t.contrast...
        *exp((linspace(t.duration/2,0,nt).^2)/DIV);

    % use the 16-bit gamma table in dXscreen
    gam = rGet('dXscreen', 1, 'gamma16bit');

    % pack gamma-corrected 16-bit gray images
    %   into 8-bit RGB space for mono++
    t.images = zeros(2*HPIX, 2*HPIX, 3, nt);
    for n = 1:nt
        % modelFest contrast:
        % L(g) = L0*(1 + c/127 * (g-128));
        img = gam(1+round((2^16-1)*t.bgLum ...
            *(1+(cGaus(n)/127)*(ff-128))));

        % pack most signif byte into red channel
        %   MATLAB is a
        t.images(:,:,1,n) = uint8(floor(img/256));

        % pack least signif byte into green channel
        t.images(:,:,2,n) = uint8(mod(img, 256));

        % pack nothing into blue channel
        %   (it can act as an overlay)
    end

    % how to order/reuse images when drawing
    %   show the maximum and minimum frames exactly once.
    %   show the intermediate frames exactly twice.
    t.imageIndices = [1:nt, nt-1:-1:2];

    % set the bgColor to support a private background
    bg = gam(1 + round((2^16-1)*t.bgLum));
    t.bgColor(3) = 0;
    t.bgColor(2) = uint8(mod(bg, 256));
    t.bgColor(1) = uint8(floor(bg/256));

    % this is way fun
    % shows gamma-corrected voltages,
    %   so may look kinda too high and up-down asymmetric.
    %for i=t.imageIndices;surf(256*t.images(:,:,1,i)+t.images(:,:,2,i));view(45,0);zlim([0,2^16-1]);drawnow;end
end