function dus_ = update(dus_)
%update method for class dXdu: recompute values on-the-fly
%   dus_ = update(dus_)
%
%   All DotsX control classes havce update methods which allow instances
%   to increment or recompute values at any time(s) during a trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Update method for class dXdu (down/up)
%-%
%-% Arguments:
%-%   dus_ ... array of dXdu objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also update dXdu

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% get the pointed value
for udi = 1:length(dus_)
    
    % ptr is {'name', index, property}
    if ~isempty(dus_(udi).ptr)

        % get value/angle to check as down or up
        if size(dus_(udi).ptr, 2) == 2
            angl = get(ROOT_STRUCT.(dus_(udi).ptr{1})(1), dus_(udi).ptr{2});
        else
            angl = get(ROOT_STRUCT.(dus_(udi).ptr{1})(dus_(udi).ptr{2}), ...
                dus_(udi).ptr{3});
        end

        % returns 0=down if pi < angle <= 2pi
        dus_(udi).value = sin(dus_(udi).intercept + dus_(udi).coefficient.*angl)>=0;
    end
end
