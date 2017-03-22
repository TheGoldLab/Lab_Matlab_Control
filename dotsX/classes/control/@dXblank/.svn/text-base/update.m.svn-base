function bk_ = update(bk_)
%update method for class dXblank: recompute values on-the-fly
%   bk_ = update(bk_)
%
%   All DotsX control classes havce update methods which allow instances
%   to increment or recompute values at any time(s) during a trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Update method for class dXblank
%-%
%-% Arguments:
%-%   bk_ ... array of dXblank objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also update dXblank

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% get the pointed value
for bki = 1:length(bk_)
    
    % ptr is {'name', index, property}
    if ~isempty(bk_(bki).ptr)

        % get any value from another object
        if size(bk_(bki).ptr, 2) == 2
            val = get(ROOT_STRUCT.(bk_(bki).ptr{1})(1), bk_(bki).ptr{2});
        else
            val = get(ROOT_STRUCT.(bk_(bki).ptr{1})(bk_(bki).ptr{2}), ...
                bk_(bki).ptr{3});
        end

        % value considered blank (non-stim) 
        %   if it equals some reference value (e.g. 0)
        bk_(bki).value = bk_(bki).blankValue ~= val;
    end
end