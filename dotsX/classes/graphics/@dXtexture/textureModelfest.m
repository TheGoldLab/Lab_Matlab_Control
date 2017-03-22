function t = modelfestTexture(t, varargin)
%   8-bit RGB packed in in t.images,
%   a set of indices into those images in t.ImageIndices
%   possibly set the continuous flag in t.continuous
%   possibly set things like lum and color

% any of the textures used in modelfest,
% identified by index 1:43
%   see http://vision.arc.nasa.gov/modelfest/stimuli.html
%   and http://journalofvision.org/5/9/6/article.aspx

% get all the modelfest images
imgf = fopen('modelfest-stimuli');
AA = fread(imgf);
fclose(imgf);

% fold bytes into 43 images, each 256x256
AA = reshape(AA, 256, 256, 43);

% which image are we using?
aa = AA(:,:,t.modelFestIndex)';

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
    t.images = zeros(256, 256, 3, nt);
    for n = 1:nt
        % modelFest contrast:
        % L(g) = L0*(1 + c/127 * (g-128));
        img = gam(1+round((2^16-1)*t.bgLum ...
            *(1+(cGaus(n)/127)*(aa-128))));

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
