function old_name_ = rGroup(name, index, specs, alter)
%Create a new group for DotsX class instances or activate an existing group
%   old_name_ = rGroup(name, index, specs, alter)
%
%   rGroup allows DotsX to maintain separate groups of object instances
%   wich may be activated independently.  For example, objects instances
%   relavant to a reaction time task might be activated separately from
%   those relevant to an interrogation task.
%
%   Object instances that are active appear in the top level of the global
%   ROOT_STRUCT; e.g. ROOT_STRUCT.dXdots.  They are accessible to DotsX
%   root functions like rSet and other DotsX functions.  Inactive objects
%   are stored in a different location and are not easily accessed.
%
%   Arguments:
%       name identifies the group to be created ot activated. default
%           'root', which is a special group that consists of objects
%            that are *always* active. Keyword 'current' specifies current
%            group.
%       index is the index into ROOT_STRUCT.groups.(name) -- in other
%           words, there can be multiple groups of the same name
%       specs is an optional cell array specifying new classes/groups
%           to be added to the given group. Usage:
%               {'class_name', <number>, {rAdd args}, {class args}; ...
%                'group_name', <number>, true/false, []; ...
%           where the first line specifies a call to rAdd, the second
%           line specifies a 'sub-group' to add (third arg is whether
%           or not to reuse a matched group in ROOT_STRUCT.groups)
%           -or-
%           keys: 'r' (remove), 'w' (write), 'a' (append)
%       alter is an optional cell array of arguments to pass to a group
%          definition function (a group in a file).  Only some group
%          definition functions can take args.
%
%   Object instances created with rAdd will belong to the currently
%   activated group.  The following creates the groups 'left' and 'right'
%   and demonstrates how to swap between them.
%
%   % setup non-task-specific objects.
%   rInit('local');
%
%   % create a new group called 'left'
%   %   and add some relevant graphics
%   rGroup('left');
%   rAdd('dXdots', 1, 'x', -5, 'y', -5);
%   rAdd('dXtext', 1, 'x', -7, 'string', 'left side, yo');
%
%   % create a similar group called 'right'
%   rGroup('right');
%   rAdd('dXdots', 1, 'x', 5, 'y', -5);
%   rAdd('dXtext', 1, 'x', 3, 'string', 'yo, right side');
%
%   % activate the 'left' group and show graphics
%   rGroup('left');
%   rGraphicsShow;
%   rGraphicsDraw(2000);
%
%   % switch to the 'right' group
%   rGroup('right');
%   rGraphicsShow;
%   rGraphicsDraw(2000);
%
%   % show both groups
%   rGroup();
%   rGraphicsShow;
%   rGraphicsDraw(2000);
%
%  Note that the group specifier ROOT_STRUCT.groups.<name> is:
%   {'class_name', [indices], {rAdd args}, {class args}; ...}
%
%   See also rAdd rInit

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

%%
% Check args
if nargin < 1 || isempty(name)
    name = 'root';
elseif strcmp(name, 'current')
    name = ROOT_STRUCT.groups.name;
end

if nargin < 2 || isempty(index) || index < 1 || strcmp(name, 'root')
    index = 1;
end

%disp(sprintf('rGroup init %s %d', name, index))

if nargin < 3
    specs = {};
elseif ischar(specs)
    
    % send command remotely
    if ROOT_STRUCT.screenMode == 2
        sendMsgH(sprintf('rGroup(''%s'',%d,''a'');', name, index));
    end

    % weird special case -- add group to existing group spec
    gn = ROOT_STRUCT.groups.name;
    gi = ROOT_STRUCT.groups.index;
    ROOT_STRUCT.groups.(gn)(gi).specs = ...
        cat(1, ROOT_STRUCT.groups.(gn)(gi).specs, {name, index, false, {}});

    % Swap in the group
    swap_in(ROOT_STRUCT.groups.(name)(index).specs);

    % outta
    return
end

if nargin < 4
    alter = {};
end

%%
% If no group given and no group active, or given
%   group is already active, outta.
if strcmp(name, ROOT_STRUCT.groups.name) && (index == ROOT_STRUCT.groups.index)
    return
end

%%
% create a remote group, if necessary
if ROOT_STRUCT.screenMode == 2
    sendMsgH(sprintf('rGroup(''%s'',%d);', name, index));
end

%%
% get current group name, index
cname = ROOT_STRUCT.groups.name;
if strcmp(cname, 'root')
    ROOT_STRUCT.groups.index = 1;
end
cindex = ROOT_STRUCT.groups.index;

%%
% OUT WITH THE OLD
%
% swap out the methods list
ROOT_STRUCT.groups.(cname)(cindex).methods = ROOT_STRUCT.methods;

% Loop BACKWARDS through the group list...this is because
%   all new (grouped) objects are added to the BEGINNING of
%   the active array. Thus, when we remove them we pull them
%   off of the beginning, last first....
%   Note that the specs cell array is always empty for the root
%   group, so this loop is bypassed in that case.
cspecs = ROOT_STRUCT.groups.(cname)(cindex).specs;
while ~isempty(cspecs)

    if strncmp(cspecs{end, 1}, 'dX', 2)

        % A name with prefix dX- indicates a class ...
        %   swap out the objects, which are always listed FIRST
        %   in the active array
        ROOT_STRUCT.classes.(cspecs{end, 1}).objects(cspecs{end, 2}) = ...
            ROOT_STRUCT.(cspecs{end, 1})(1:size(cspecs{end, 2}, 2));

        % remove them from the active list
        ROOT_STRUCT.(cspecs{end, 1})(1:size(cspecs{end, 2}, 2)) = [];

        % clear entry
        cspecs(end, :) = [];
    else

        % Otherwise it's a group ... add specs to end of cspecs
        cspecs = cat(1, cspecs(1:end-1,:), ...
            ROOT_STRUCT.groups.(cspecs{end,1})(cspecs{end,2}).specs);
    end
end

%%
% IN WITH THE NEW
%

% if the new group is not 'root' (which is already active),
%   activate its members
if ~strcmp(name, 'root')

    % check first if the given group exists
    if any(strcmp(name, ROOT_STRUCT.groups.names)) && ...
            size(ROOT_STRUCT.groups.(name), 2) >= index

        % swap in the methods list
        ROOT_STRUCT.methods = ROOT_STRUCT.groups.(name)(index).methods;

        % The group we want does exist, so swap it in...
        swap_in(ROOT_STRUCT.groups.(name)(index).specs);

    else

        % group does not exist

        % swap in the root methods list
        ROOT_STRUCT.methods = ROOT_STRUCT.groups.root.methods;

        % group does not exist... create it
        ROOT_STRUCT.groups.(name)(index) = struct( ...
            'specs',    {{}},                      ...
            'methods',  ROOT_STRUCT.methods);
        
        % only add name to names list once
        if ~any(strcmp(name, ROOT_STRUCT.groups.names))
            ROOT_STRUCT.groups.names = cat(2, ROOT_STRUCT.groups.names, name);
        end

        % Try to get specs from file if NOT remote
        if ~(isfield(ROOT_STRUCT, 'isClient') && ROOT_STRUCT.isClient) ...
                && ~isempty(which(name))
            if ~isempty(alter) && iscell(alter)
                % pass args to group function?
                specs = cat(1, specs, feval(name, alter{:}));
            else
                specs = cat(1, specs, eval(name));
            end
        end
    end
else

    % swap in the root methods list
    ROOT_STRUCT.methods = ROOT_STRUCT.groups.root.methods;
end

% make it the current group
ROOT_STRUCT.groups.name  = name;
ROOT_STRUCT.groups.index = index;

% add objects/groups from new_specs:
%   { <class_name>, num, <rAdd args>,    <class args>; ...
%     <group_name>, num, true/false, []; ...
%   Where the third argument of the group specifier
%       is a boolean reuse flag -- make a new group
%       or just use one that already exists
for ii = 1:size(specs, 1)

    % check for num (second arg)
    if isempty(specs{ii, 2})
        specs{ii, 2} = 1;
    end

    if specs{ii, 2} > 0

        if strncmp(specs{ii, 1}, 'dX', 2)

            % If name = 'dX*', it's a class ... add it.
            %   Third argument is {args} to send to rAdd
            rAdd(specs{ii, 1:3}, specs{ii, 4}{:});
        else
            
            % Otherwise it's a sub-group...
            % First check reuse flag -- we can only reuse
            %   as many as we have
            if any(strcmp(specs{ii, 1}, ROOT_STRUCT.groups.names))
                num_exist = size(ROOT_STRUCT.groups.(specs{ii, 1}), 2);
            else
                num_exist = 0;
            end
            
            if isempty(specs{ii,3}) || (islogical(specs{ii,3}) && specs{ii, 3})
                to_reuse = min(specs{ii, 2}, num_exist);
            else
                to_reuse = 0;
            end

            % Loop through the number of sub-groups to reuse
            for ss = 1:specs{ii, 2}

                % if run out of reusable group instances, make a new one, 
                % then swap current group back in
                if ss > to_reuse
                    rGroup(specs{ii, 1}, ss+num_exist, {}, specs{ii, 4});
                    rGroup(name, index);
                end

                % add it.. we need to do it this way for the sake
                %   of the remote system.
                rGroup(specs{ii, 1}, ss+num_exist-to_reuse, 'a');
            end
        end
    end
end

%disp('rGroup done')

%%%%%
%
function swap_in(specs)

global ROOT_STRUCT

while ~isempty(specs)

    if strncmp(specs{1, 1}, 'dX', 2)

        % class specifier, check for args
        if specs{1, 3} && ~isempty(specs{1, 4})

            % prepend objects after calling set method
            ROOT_STRUCT.(specs{1, 1}) = cat(2, set(...
                ROOT_STRUCT.classes.(specs{1, 1}).objects(specs{1, 2}), ...
                specs{1, 4}{:}), ROOT_STRUCT.(specs{1, 1}));
        else

            % prepend objects
            ROOT_STRUCT.(specs{1, 1}) = cat(2, ...
                ROOT_STRUCT.classes.(specs{1, 1}).objects(specs{1, 2}), ...
                ROOT_STRUCT.(specs{1, 1}));
        end

        % clear entry
        specs(1,:) = [];

    else

        % Otherwise it's a group ... add specs to beginning of specs
        grp    = ROOT_STRUCT.groups.(specs{1,1})(specs{1,2});
        specs = cat(1, grp.specs, specs(2:end,:));

        % Swap in the methods list. This is ugly -- but necessary,
        %   I think... objects might have been added to this sub-group
        %   separately, but there's no good way of keeping track of
        %   all of the groups it is a member of...
        for mm = grp.methods.names
            if any(strcmp(mm{:}, ROOT_STRUCT.methods.names))
                ROOT_STRUCT.methods.(mm{:}) = union( ...
                    ROOT_STRUCT.methods.(mm{:}), grp.methods.(mm{:}));
            else
                ROOT_STRUCT.methods.(mm{:}) = grp.methods.(mm{:});
            end
        end
    end
end