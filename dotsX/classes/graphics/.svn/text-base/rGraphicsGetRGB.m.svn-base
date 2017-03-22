function rgb_ = rGraphicsGetRGB(ptrOrLum, g)
%convert a pointer or luminance to an rgb triple
%   rgb_ = rGraphicsGetRGB(ptrOrLum, g)
%
%   ptrOrLum may be a DotsX-style pointer of the form
%       {'class_name', index, 'propery'},
%   which should point to a valid color property of another object.
%
%   ptrOrLum may be a scalar luminance in the interval [0,1), in which case
%   it will be converted to an equivalent rgb triplet: if dXscreen is using
%   its mono++ gamma correction table, the triplet will be in 16-bit mono++
%   format.  Otherwise the triplet will be in standard 8-bit rgb format.
%
%   If ptrOrLum is already a standard rgb triple or an integer CLUT index, it
%   will be returned unchanged.
%
%   g may be the current instance of dXcreen as a struct.  g is optional.

% Copyright 2007 by Benjamin Heasly, University of Pennsylvania

global ROOT_STRUCT

% get real
if ~nargin
    rgb_ = [];
    return
elseif nargin < 2 || isempty(g)
    g = struct(ROOT_STRUCT.dXscreen(1));
end

% ptrOrLum can be a pointer.  Resolve it.
if iscell(ptrOrLum)
    ptrOrLum = get(ROOT_STRUCT.(ptrOrLum{1})(ptrOrLum{2}), ptrOrLum{3});
end

% ptrOrLum can be a scalar luminance.  Explode it to rgb.
%   the value 1 is ambiguous, ignore it as a clutX index.
if isscalar(ptrOrLum) && ptrOrLum < 1 && ptrOrLum >=0
    if g.loadGammaBitsPlus
        % using 16-bit mono++, pack MSB red and LSB green
        %   must do 'manual' gamma correction by lookup
        lum16bit = g.gamma16bit(1+round(ptrOrLum*(2^16-1)));
        rgb_(3) = 0;
        rgb_(2) = uint8(mod(lum16bit, 256));
        rgb_(1) = uint8(floor(lum16bit/256));
    else
        % using normal 8-bit color
        %   gamma correction should be done on the graphics card.
        rgb_ = [1,1,1]*255*ptrOrLum;
    end
else
    rgb_ = ptrOrLum;
end