function rClear(no_clear)
% function rClear(no_clear)
%
%   Return DotsX and ROOT_STRUCT to a clean, just-initialized state
%
%   rClear scrubs ROOT_STRUCT of everything except classes
%   listed in "no_clear" (default is all classes with a "root" method). 
%   Members of noClear MUST be in the root group (all other groups are cleared
%   automatically).
% 
%   rClear allows DotsX to start over without calling rInit again.  This also
%   allows a remote graphics client to reset itself without the user
%   manually quitting and restarting rRemoteClient.
%
%   The following adds some DotsX graphics, then removes them.
%
%   rInit('debug')
%   rAdd('dXdots', 1);
%   rClear
%
%   This is equivalent to
%
%   rInit('debug')
%
%   See also rInit rAdd dXdots

% Copyright 2006 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% check args
if nargin < 1 || isempty(no_clear)
	no_clear = ROOT_STRUCT.methods.root;
end

% Ungroup (i.e., set to root group), then remove all other groups
rGroup;
ROOT_STRUCT.groups = ...
    struct('name','root','index',1,'names',{{}},'root',struct('specs', {{}},'methods',[]));

% remove all classes *except* those listed in no_clear
to_clear = setdiff(ROOT_STRUCT.classes.names, no_clear);
if ~isempty(to_clear)
    ROOT_STRUCT         = rmfield(ROOT_STRUCT,         to_clear);
    ROOT_STRUCT.classes = rmfield(ROOT_STRUCT.classes, to_clear);
end
ROOT_STRUCT.classes.names = intersect(no_clear, ROOT_STRUCT.classes.names);

% go through the existing classes to update object
%   lists and methods
ROOT_STRUCT.methods = struct('names', {{}});
for cl = ROOT_STRUCT.classes.names

    % Check if there are any active objects
    if ~size(ROOT_STRUCT.(cl{:}), 2)
        ROOT_STRUCT               = rmfield(ROOT_STRUCT, cl);
        ROOT_STRUCT.classes       = rmfield(ROOT_STRUCT.classes, cl);
        ROOT_STRUCT.classes.names = setdiff(ROOT_STRUCT.classes.names, cl);
    else
        % Clear out extra objects (i.e., those that were in
        %   other (non-root) groups). Remember that objects
        %   in the root group are always the last in the master array
        ROOT_STRUCT.classes.(cl{:}).objects   = ROOT_STRUCT.(cl{:});
        ROOT_STRUCT.classes.(cl{:}).root_inds = 1:size(ROOT_STRUCT.(cl{:}),2);
        
        % updating methods -- see rAdd for details
        for mt = ROOT_STRUCT.classes.(cl{:}).methods
            if ~any(strcmp(mt{:}, ROOT_STRUCT.methods.names))
                % new method
                ROOT_STRUCT.methods.names   = cat(2, ROOT_STRUCT.methods.names, mt{:});
                ROOT_STRUCT.methods.(mt{:}) = cl;
            else
                % Existing method
                ROOT_STRUCT.methods.(mt{:}) = cat(2, cl, ROOT_STRUCT.methods.(mt{:}));
            end
        end
    end
end

% clear times and messages that rRemoteClient may have stored
if isfield(ROOT_STRUCT, 'clientRecord')
    ROOT_STRUCT.clientRecord = cell(1e5,5);
end
