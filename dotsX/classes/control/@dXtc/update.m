function tcs_ = update(tcs_)
%update method for class dXtc: recompute values on-the-fly
%   tcs_ = update(tcs_)
%
%   All DotsX control classes havce update methods which allow instances
%   to increment or recompute values at any time(s) during a trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Update method for class dXtc (tuning curve). Uses
%-%   current value or override to write to ptr.
%-%
%-% Arguments:
%-%   tcs_ ... array of tuning curve objects
%-%
%-% Returns:
%-%   tcs_ ... the array of objects, which have been
%-%               changed because previousValue is updated
%----------Special comments-----------------------------------------------
%
%   See also update dXtc

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

if length(tcs_) == 1

    % Only one tc object ...
    if isempty(tcs_.override)

        % use current value
        value = tcs_.value;

    else

        % use override
        value = tcs_.override;
    end

    % optional update
    if isnan(value)
        return
    end

    % ptr is {'name', index, property}
    switch tcs_.ptrType

        case 1

            % all objects
            ptr = tcs_.ptr;
            ROOT_STRUCT.(ptr{1}) = set( ...
                ROOT_STRUCT.(ptr{1}), ptr{3}, value);

        case 2

            % indexed objects
            ptr = tcs_.ptr;
            ROOT_STRUCT.(ptr{1})(ptr{2}) = set( ...
                ROOT_STRUCT.(ptr{1})(ptr{2}), ptr{3}, value);
    end

else

    % Multiple tc objects ...
    % First check if they all "point" to the same object
    ptrs = {tcs_.ptrClass};
    inds = [tcs_.ptrIndex];
    if all(strcmp(ptrs{1}, ptrs)) ...
            && length(inds)==length(tcs_) && all(inds==inds(1))

        arglist = {};
        for tci = 1:length(tcs_)

            if isempty(tcs_(tci).override)

                % use current value
                value = tcs_(tci).value;

            else

                % use override
                value = tcs_(tci).override;
            end

            % optional update
            if isnan(value)
                continue
            else
                arglist = cat(2, arglist, ...
                    {tcs_(tci).ptr{3}, value});
            end
        end

        % send command, same indexed object
        % indexed objects
        ROOT_STRUCT.(ptrs{1})(inds(1)) = set( ...
            ROOT_STRUCT.(ptrs{1})(inds(1)), arglist{:});

    else

        % different pointer, loop through each one...
        for tci = 1:length(tcs_)

            if isempty(tcs_(tci).override)

                % use current value
                value = tcs_(tci).value;

            else

                % use override
                value = tcs_(tci).override;
            end

            % optional update
            if isnan(value)
                continue
            end

            % ptr is {'name', index, property}
            ptr = tcs_(tci).ptr;

            if ~isempty(ptr)
                if isempty(ptr{2})

                    % all objects
                    ROOT_STRUCT.(ptr{1}) = set( ...
                        ROOT_STRUCT.(ptr{1}), ptr{3}, value);
                else

                    % indexed objects
                    ROOT_STRUCT.(ptr{1})(ptr{2}) = set( ...
                        ROOT_STRUCT.(ptr{1})(ptr{2}), ptr{3}, value);
                end
            end
        end
    end
end
