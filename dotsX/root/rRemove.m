function rRemove(class_name, indices)
%Remove one or more class instance from ROOT_STRUCT
%   rRemove(class_name, indices)
%
%   rRemove deletes class instances from ROOT_STRUCT and manages lists in
%   ROOT_STRUCT of existing classes and methods.
%
%   class_name must be the string name of an object previously created
%   with rAdd.  indices may be a 1-by-N array of integers indicating which
%   instances of class_name should be deleted.
%
%   If indices is the empty [], the string 'all', or not provided, all
%   instances of class_name will be deleted.
%
%   When the last instance of class_name is deleted, references in
%   ROOT_STRUCT to class_name and its methods will be removed.  Removal of
%   an entire class in this way will affect all groups.
%
%   In remote graphics mode, rRemove attempts to remove graphics objects
%   residing on the remote client machine.
%
%   The following will create two instances of the dXtext class and remove
%   one of them.
%
%   rInit('debug');
%   rAdd('dXtext', 2, 'string', {'remove me', 'keep me'});
%   rRemove('dXtext', 1);
%   rGet('dXtext', 1, 'string')
%
%   See also rInit rAdd rGet rGroup dXtext

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

% check that the class exists
if ~isfield(ROOT_STRUCT, class_name)
    return
end

% remove remote objects
if ROOT_STRUCT.screenMode == 2 && isfield(ROOT_STRUCT, 'draw') ...
        && any(strcmp(ROOT_STRUCT.methods.draw, class_name))
    sendMsgH(sprintf('rRemove(''%s''%s);', class_name, sprintf(',%d',indices)));
end

% remove objects
if nargin < 2 || isempty(indices) || strcmp(indices, 'all') || ...
        length(indices) == length(ROOT_STRUCT.(class_name))

    % Removing all class instance,
    %   so remove batch method listings
    for met = ROOT_STRUCT.classes.(class_name).methods

        % check for 'root' method and call with 'clear' flag
        if strcmp(met{1}, 'root')
            ROOT_STRUCT.(class_name) = ...
                root(ROOT_STRUCT.(class_name), 'clear');
        end

        % Remove class entry from active methods list
        ROOT_STRUCT.methods ...
            .(met{1})(strcmp(class_name, ROOT_STRUCT.methods.(met{1}))) = [];

        % If removing the last class with given method...
        if isempty(ROOT_STRUCT.methods.(met{1}))

            % remobe the method itself from active methods list
            ROOT_STRUCT.methods.names(strcmp(met{1}, ROOT_STRUCT.methods.names)) = [];
            ROOT_STRUCT.methods = rmfield(ROOT_STRUCT.methods, met{1});
        end
    end

    % remove top-level field
    ROOT_STRUCT = rmfield(ROOT_STRUCT, class_name);

    % remove class
    ROOT_STRUCT.classes = rmfield(ROOT_STRUCT.classes, class_name);

    % remove from big class name list
    ROOT_STRUCT.classes.names(strcmp(class_name,   ROOT_STRUCT.classes.names))   = [];

else

    % remove by indices from top level
    ROOT_STRUCT.(class_name)(indices) = [];
end

