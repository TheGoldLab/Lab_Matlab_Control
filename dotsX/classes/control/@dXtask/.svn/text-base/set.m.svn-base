function ta_ = set(ta_, varargin)
%set method for class dXtask: specify property values and recompute dependencies
%   ta_ = set(ta_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of a task object(s).
%-% This baby's relatively slow -- not intended
%-%   to be called within a state loop
%----------Special comments-----------------------------------------------
%
%   See also set dXtask

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% one little error check ... naah
%if length(ta_) > 1
%    error('   ... Only one task can be set at a time')
%end

global ROOT_STRUCT

% Check for property changes that call for a 'reset'
%   is it worth ~0.25ms to check for actual value changes??
doReset = false;
for prop = ta_.requireReset
    val = varargin(find(strcmp(varargin(1:2:end), prop))*2);
    if ~isempty(val)
        if isnumeric(val)
            doReset = ~isequal(val, ta_.(prop{1}));
        elseif ischar(val)
            doReset = ~strcmp(val, ta_.(prop{1}));
        else
            doReset = true;
            break
        end
        if doReset
            break
        end
    end
end

% loop through the arguments, setting valuess
for ii = 1:2:size(varargin, 2)
    ta_.(varargin{ii}) = varargin{ii+1};
end

if iscell(ta_.helpers) && size(ta_.helpers, 2) == 4

    % make group with one set of helpers
    rGroup(ta_.name, 1, ta_.helpers);

    % clear so we don't do this again
    ta_.helpers = [];
end

% set saveToFIRA
if iscell(ta_.objectsToFIRA) && ~isempty(ta_.objectsToFIRA)

    %%%%
    % OBJECTSTOFIRA
    %%%%
    %
    % objectsToFIRA, specifying which helper objects
    %   with 'saveToFIRA' methods are called at the
    %   end of a trial. Creates field saveToFIRA cell array:
    %       {<class> <indices>; ...}

    % clear
    ta_.saveToFIRA = {};

    % two input types...
    if size(ta_.objectsToFIRA, 1) == 2 && ...
            isnumeric(ta_.objectsToFIRA{1, 2})

        % objectsToFIRA is list of objects,
        %   nx2 cell array with columns
        %       - class name
        %       - indices
        % Check that objects are valid
        for ii = 1:size(ta_.objectsToFIRA, 1)
            if isfield(ROOT_STRUCT, ta_.objectsToFIRA{ii, 1})
                sz = size(ROOT_STRUCT.(ta_.objectsToFIRA{ii, 1}), 2);
                if sz > 0 && (isempty(ta_.objectsToFIRA{ii, 2}) || ...
                        sz <= max(ta_.objectsToFIRA{ii, 2}))
                    ta_.saveToFIRA = cat(1, ta_.saveToFIRA, ta_.objectsToFIRA(ii, :));
                end
            end
        end

    else

        % objectsToFIRA is list of methods, find all objects
        %   with these methods
        for mt = ta_.objectsToFIRA
            if isfield(ROOT_STRUCT, 'methods') ...
                    && isfield(ROOT_STRUCT.methods, mt{:})

                for ob = ROOT_STRUCT.methods.(mt{:})
                    if ismethod(ob{:}, 'saveToFIRA') && ...
                            isfield(ROOT_STRUCT, ob{:}) && ...
                            ~isempty(ROOT_STRUCT.(ob{:})) && ...
                            (isempty(ta_.saveToFIRA) || ...
                            ~any(strcmp(ob{:}, ta_.saveToFIRA(:,1))))
                        ta_.saveToFIRA = cat(1, ta_.saveToFIRA, {ob{:}, []});
                    end
                end
            end
        end
    end

    % clear
    ta_.objectsToFIRA = [];
end

% non-forced reset with new values,
%   must do this after adding helpers, above.
if doReset
    ta_ = reset(ta_, false);
end