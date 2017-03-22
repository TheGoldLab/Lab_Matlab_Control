function rGraphicsBlankRex
% function rGraphicsBlankRex
%
% Undraw all drawable objects without flipping Screen buffers.

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% loop through the drawables
for dr = ROOT_STRUCT.methods.blank

    % call class-specific blank on ALL objects
    ROOT_STRUCT.(dr{:}) = blank(ROOT_STRUCT.(dr{:}));
end