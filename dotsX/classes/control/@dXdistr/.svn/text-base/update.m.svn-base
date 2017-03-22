function d_ = update(d_)
%update method for class dXtc: recompute values on-the-fly
%   d_ = update(d_)
%
%   All DotsX control classes havce update methods which allow instances
%   to increment or recompute values at any time(s) during a trial.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Update method for class dXdistr (random number generator). Uses
%-%   current value or override to write to ptr.
%-%
%-% Arguments:
%-%   d_ ... array of dXdistr objects
%-%
%-% Returns:
%-%   d_ ... the array of objects, which have been
%----------Special comments-----------------------------------------------
%
%   See also update dXdistr

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

if length(d_) == 1

    % Only one tc object ...
    if isempty(d_.override)

        % use current value
        value = d_.value;

    else

        % use override
        value = d_.override;
    end

    % ptr is {'name', index, property}
    switch d_.ptrType

        case 1

            % all objects
            ptr = d_.ptr;
            ROOT_STRUCT.(ptr{1}) = set( ...
                ROOT_STRUCT.(ptr{1}), ptr{3}, value);

        case 2

            % indexed objects
            ptr = d_.ptr;
            ROOT_STRUCT.(ptr{1})(ptr{2}) = set( ...
                ROOT_STRUCT.(ptr{1})(ptr{2}), ptr{3}, value);
    end

else

    % Multiple tc objects ...
    % First check if they all "point" to the same object
    ptrs = {d_.ptrClass};
    inds = [d_.ptrIndex];
    if sum(strcmp(ptrs{1}, ptrs)) == length(d_) && ...
            length(inds) == length(d_) && sum(inds==inds(1))

        arglist = {};
        for tci = 1:length(d_)

            if isempty(d_(tci).override)

                % use current value
                arglist = cat(2, arglist, ...
                    {d_(tci).ptr{3}, d_(tci).value});

            else

                % use override
                arglist = cat(2, arglist, ...
                    {d_(tci).ptr{3}, d_(tci).override});
            end

        end
        
        % send command, same indexed object
        % indexed objects
        ROOT_STRUCT.(ptrs{1})(inds(1)) = set( ...
            ROOT_STRUCT.(ptrs{1})(inds(1)), arglist{:});

    else

        % different pointer, loop through each one...
        for tci = 1:length(d_)

            if isempty(d_(tci).override)

                % use current value
                value = d_(tci).value;

            else

                % use override
                value = d_(tci).override;
            end

            % ptr is {'name', index, property}
            ptr = d_(tci).ptr;

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
