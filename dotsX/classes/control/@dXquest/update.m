function q_ = update(q_)
%update method for class dXquest: recompute values on-the-fly
%   q_ = update(q_)
%
%   All DotsX control classes havce update methods which allow instances
%   to increment or recompute values at any time(s) during a trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Update method for class dXquest . Uses
%-%   current value or override to write to ptr.
%-%
%-% Arguments:
%-%   q_ ... array of Quest objects
%-%
%-% Returns:
%-%   q_ ... the array of objects, which may one day be changed
%-%
%----------Special comments-----------------------------------------------
%
%   See also update dXquest

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

% Quest objects act in concert ...
if isempty(q_(1).override) || isnan(q_(1).override)

    % use current value
    value = q_(1).value;

else
    
    % use override only once
    value = q_(1).override;
    q_(1).override = [];
end

% ptr is {'name', index, property}
switch q_(1).ptrType

    case 1

        % all objects
        ptr = q_(1).ptr;
        ROOT_STRUCT.(ptr{1}) = set( ...
            ROOT_STRUCT.(ptr{1}), ptr{3}, value);

    case 2

        % indexed objects
        ptr = q_(1).ptr;
        ROOT_STRUCT.(ptr{1})(ptr{2}) = set( ...
            ROOT_STRUCT.(ptr{1})(ptr{2}), ptr{3}, value);
end