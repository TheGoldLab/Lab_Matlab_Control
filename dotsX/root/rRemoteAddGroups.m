function rRemoteAddGroups
% rRemoteAddGroups
%   Send all graphics from an existing ROOT_STRUCT to a remote client
%
%   In remote graphics mode, rAdd sends new graphics objects to the remote
%   client machine immediately, when each is created.  rRemoteAddGroups
%   sends all existing graphics objects at once.  This allows server and
%   client to (re)synchronize without adding or removing objects on the
%   server.
%
%   The following simulates a client machine reboot and resynchronization
%   with rRemoteAddGroups.
%
%   % add graphics to the server and client
%   rInit('remote');
%   rAdd('dXdots', 1, 'visible', true);
%   rGraphicsDraw(3000);
%   rGraphicsBlank;
%
%   % client "reboots," remote drawing would now fail
%   sendMsg('rClear');
%
%   % resynchronize client with server graphics and show
%   rRemoteAddGroups;
%   rGraphicsShow('dXdots');
%   rGraphicsDraw(3000);
%   rGraphicsBlank;
%
%   see also rInit rClear rAdd

% 2006 by Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT

% bail out
if isempty(ROOT_STRUCT) || ROOT_STRUCT.screenMode ~= 2
    return
end

% may be redundant with rRemoteSetup
sendMsgH('rClear;');

% go to root group, like the client in rClear
rGroup('root');

% add root graphics obj to client
if isfield(ROOT_STRUCT.methods, 'draw')
    for dcl = ROOT_STRUCT.methods.draw
        obj = struct(ROOT_STRUCT.(dcl{1}));
        objf = [obj.fields];
        fields = fieldnames(objf);
        fieldl = length(fields);

        % pack up dXremote/set rAdd args
        % 	don't reuse, do call set, don't save these args
        args = cell(1, fieldl*2+3);
        args(1:3) = {obj(1).class, [obj.index], {'root', false, true, false}};
        for fn = 1:length(fields)
            % add property name to arg list
            an = fn*2+2;
            args(an) = fields(fn);

            % add data to arglist
            allVals = {objf.(fields{fn})};
            if isempty(allVals) || numel(allVals)==1 || isequal(allVals{:})
                % all same, use one uncelled entry
                args{an+1} = allVals{1};
            else
                % different values, use a cell
                args{an+1} = allVals;
            end
        end

        % set em to remote client via dXremote
        ROOT_STRUCT.(dcl{1}) = set(ROOT_STRUCT.(dcl{1}), args{:});
    end
end

% add all groups and any drawable objects to client
ri = strcmp(ROOT_STRUCT.groups.names, 'root');
for gru = ROOT_STRUCT.groups.names(~ri)

    % groups can have multiple instances
    g = [ROOT_STRUCT.groups.(gru{1})];
    for ii = 1:length(g)

        % declare this group remotely
        msg = sprintf('rGroup(''%s'', %d);', gru{1}, ii);
        %disp(msg)
        sendMsgH(msg);

        % get a shorthand copy of group specifier
        gs = g(ii).specs;

        % remote-add drawable class instances to group
        if ~isempty(gs) && isfield(ROOT_STRUCT.groups.(gru{1})(1).methods, 'draw')
            for dcl = intersect(gs(:,1), g(ii).methods.draw)
                row = find(strcmp(gs(:,1), dcl{1}));

                % if there are group arguments saved for this class/row,
                % apply them to all instanes.  Otherwise, send fieldnames
                % and values verbatim from each instance.

                % any args in the last column of specs?
                if isempty(gs{row, 4})

                    % pack up dXremote/set args from dXtext.fields
                    obj = struct(ROOT_STRUCT.classes.(dcl{1}).objects(gs{row,2}));
                    objf = [obj.fields];
                    fields = fieldnames(objf);
                    fieldl = length(fields);

                    % don't reuse, do call set, don't save these args
                    args = cell(1, fieldl*2+3);
                    args(1:3) = {obj(1).class, [obj.index], {gru{1}, false, true, false}};
                    for fn = 1:length(fields)
                        an = fn*2+2;

                        % add property name to arg list
                        args(an) = fields(fn);

                        % add data to arglist
                        allVals = {objf.(fields{fn})};
                        if length(allVals)==1 || isequal(allVals{:})
                            % all same, use one uncelled entry
                            args{an+1} = allVals{1};
                        else
                            % different values, use a cell
                            args{an+1} = allVals;
                        end
                    end
                else

                    % add and set according to arguments saved in specs
                    % 	don't reuse, do call set, do save these args
                    args = {dcl{1}, gs{row, 2}, {gru{1}, false, true, true}, ...
                        gs{row, 4}{:}};
                end

                % set em all on the remote client, via dXremote
                ROOT_STRUCT.classes.(dcl{1}).objects(gs{row,2}) = ...
                    set(ROOT_STRUCT.classes.(dcl{1}).objects(gs{row,2}), ...
                    args{:});
            end
        end
    end
end

% remote add subgroup names to supergroup specs
%   must do this after all groups are created, above
%   the alternative is recursion.  KIS, S.
for gru = ROOT_STRUCT.groups.names(~ri)

    % group struct or struct array of group instances
    g = [ROOT_STRUCT.groups.(gru{1})];

    % Many groups contain no subgroups--skip em.
    if ~isempty(g(1).specs) && any(strncmp('gX', g(1).specs(:,1), 2))

        % add subgroups to all supergroup instances
        for ii = 1:length(g)

            % activate this group remotely
            msg = sprintf('rGroup(''%s'', %d);', gru{1}, ii);
            %disp(msg)
            sendMsgH(msg);

            % remote add subgroup names to group specs
            if ~isempty(g(ii).specs)
                for row = find(strncmp('gX', g(ii).specs(:,1), 2))'
                    msg = sprintf('rGroup(''%s'',%d,''a'');', g.specs{row, 1:2});
                    %disp(msg)
                    sendMsgH(msg);
                end
            end
        end
    end
end

% remote-activate root group, to match server here
sendMsgH('rGroup(''root'');');