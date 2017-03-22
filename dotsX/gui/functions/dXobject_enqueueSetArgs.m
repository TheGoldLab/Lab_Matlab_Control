function dXobject_enqueueSetArgs(obj, event, doFlush, pObject, fig)
% function dXobject_enqueueSetArgs(obj, event, doFlush, pObject, fig)
%
% Add arguments for a dX___/set to a running queue and possibly flush the
% queue by passing off all args to dX___/set and rebuilding the dXobjectGUI
%
% Args:
%   obj         ... handle to the 'Set changes' button of a dXobjectGUI
%
%   event       ... may contain a {property, value} pair to enqueue
%
%   doFlush     ... logical flag to flush queue or not
%
%   pObject     ... cell pointer to a dX___ instance in ROOT_STRUCT
%
%   fig         ... handle for the figure of a dXobjectGUI instance
%
% 2006 by Benjamin Heasly at University of Pennsylvania

queue = get(obj,'UserData');

% enqueue any setArgs, allow only one entry per dX___ field
if ~isempty(event)
    qi = find(strcmp(queue(1:2:end),event{1}))*2;
    if isempty(qi)
        queue = cat(2,queue,event);
    else
        queue(qi-1:qi) = event;
    end
end

if doFlush && ~isempty(queue)
    % dX___ instance is either in top of ROOT_STRUCT or in ROOT_STRUCT.classes
    % find it, call set with args in queue

    global ROOT_STRUCT

    dXi = pObject{end};
    if strcmp(pObject{1},'classes')
        dXname = pObject{2};
        ROOT_STRUCT.classes.(dXname).objects(dXi) = ...
            set(ROOT_STRUCT.classes.(dXname).objects(dXi), queue{:});
    else
        dXname = pObject{1};
        ROOT_STRUCT.(dXname)(dXi) = ...
            set(ROOT_STRUCT.(dXname)(dXi), queue{:});
    end

    % rebuild the objectGUI
    dXobject_makeWidgets(nan, [], fig);

else
    % save queue for laaaaaaaate
    set(obj,'UserData',queue);
end