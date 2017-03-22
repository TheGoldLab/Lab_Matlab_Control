function lrs_ = update(lrs_)
%update method for class dXlr: recompute values on-the-fly
%   lrs_ = update(lrs_)
%
%   All DotsX control classes havce update methods which allow instances
%   to increment or recompute values at any time(s) during a trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Update method for class dXlr (left/right)
%-%
%-% Arguments:
%-%   lrs_ ... array of left/right objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also update dXlr

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% get the pointed value
for lri = 1:length(lrs_)
    
    % ptr is {'name', index, property}
    if ~isempty(lrs_(lri).ptr)

        % get value/angle to check as left or right
        if size(lrs_(lri).ptr, 2) == 2
            angl = get(ROOT_STRUCT.(lrs_(lri).ptr{1})(1), lrs_(lri).ptr{2});
        else
            angl = get(ROOT_STRUCT.(lrs_(lri).ptr{1})(lrs_(lri).ptr{2}), ...
                lrs_(lri).ptr{3});
        end

        % returns 0=left if pi/2 >= angle > 3pi/2
        lrs_(lri).value = cos(lrs_(lri).intercept + lrs_(lri).coefficient.*angl)>=0;
    end
end
