function b_ = set(b_, varargin)
%set method for class dXbeep: specify property values and recompute dependencies
%   b_ = set(b_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% sets properties of a dXbeep object
%----------Special comments-----------------------------------------------
%
%   See also set dXbeep

% Copyright 2004 by Joshua I. Gold
%   University of Pennsylvania

% set the fields, one at a time.. no error checking
for ii = 1:2:nargin-1

    % change it
    if iscell(varargin{ii+1}) && ~isempty(varargin{ii+1})
        [b_.(varargin{ii})] = deal(varargin{ii+1}{:});
    else
        [b_.(varargin{ii})] = deal(varargin{ii+1});
    end
end

% make the sound(s) as sinusoids
for ii = 1:length(b_)

    if b_(ii).mute
        % nice to mute the beeps during debugging.
        %   (esp. when rocking out on sweet music.)
        b_(ii).sound = [0,0];
    else
        b_(ii).sound = b_(ii).gain .* sin(2*pi*b_(ii).frequency* ...
            linspace(0, b_(ii).duration, ...
            b_(ii).sampleFrequency*b_(ii).duration));
    end
end