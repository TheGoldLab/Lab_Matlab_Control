function dXobject_makeWidgets(obj, event, fig)
% function dXobject_makeWidgets(obj, event, fig)
%
% Make a nice widget for each of the non-auto fields of a dX___ object.
%
% Args:
%   ojb     ... handle of calling object--a widget
%   event   ... any event data, maybe none
%   fig     ... the figure of a dXobjectGUI instance
%
% Returns: zilch, updates guidata for fig
%
% 2006 Benjamin Heasly at University of Pennsylvania

global ROOT_STRUCT

% should not happen
if isempty(fig)
    disp('better to pass fig to dXobject_makeWidgets(...)')
    fig = get(obj,'Parent');
end

% get handles from fig.
handles = guidata(fig);

% dX___ instance is either in top of ROOT_STRUCT or in ROOT_STRUCT.classes
% find it, copy it, DO NOT ASSIGN ANYTHING TO IT
dXi = handles.pObject{end};
if strcmp(handles.pObject{1},'classes')
    dXname = handles.pObject{2};
    handles.dXcopy = ROOT_STRUCT.classes.(dXname).objects(dXi);
else
    dXname = handles.pObject{1};
    handles.dXcopy = ROOT_STRUCT.(dXname)(dXi);
end

% get fields of dX___ and their attribs
editAttrib(:,1) = cellstr(ROOT_STRUCT.classes.(dXname).fieldnames);
editAttrib(:,2) = struct2cell(ROOT_STRUCT.classes.(dXname).types);
editAttrib(:,3) = struct2cell(ROOT_STRUCT.classes.(dXname).ranges);

% special case for dXremote:
% get field attribs of a real graphics class
if strcmp(class(handles.dXcopy),'dXremote')
    [lame,moreAttrib] = feval(dXname,1);
    editAttrib = cat(1,editAttrib,moreAttrib(:,1:3));
end

% limit fields to non-auto fields
editi = ~strcmp(editAttrib(:,2),'auto');
editAttrib = editAttrib(editi,:);

% allocate realestate in figure for first widget
handles.widgeRect = [0, .1, 75, 1.2];

% pick columns for organizing widgets
handles.tab = [20,handles.widgeRect(3)-20];

% irradiate any existing widgets in this dXobjectGUI
delete(get(fig,'Children'));

% Make a 'Set' button to call dX___/set with any queued arguments
% ...position button in rightmost 10 characters of widgeRect realestate
pos = handles.widgeRect;
pos(1) = handles.tab(1);
pos(3) = 15;

% ...new the 'Set' button widget
handles.sbH = uicontrol(fig, ...
    'Style',        'pushbutton', ...
    'Position',     pos, ...
    'String',       'Set changes', ...
    'UserData',     {}, ...
    'Tag',          'setButton', ...
    'Callback',     {@dXobject_enqueueSetArgs, true, handles.pObject, fig});

% Make a 'Refresh' button to redraw this dXobjectGUI from dX___ fields
% ...position left of 'Set' button
pos(1) = handles.tab(2);

% ...new the button widget
uicontrol(fig, ...
    'Style',        'pushbutton', ...
    'Position',     pos, ...
    'String',       'Refresh figure', ...
    'UserData',     {}, ...
    'Tag',          'refreshButton', ...
    'Callback',     {@dXobject_makeWidgets,fig});

% ...increment widgeRect up, above 'Set' and 'Refresh' buttons,
%   to allocate realestate for the next widget(s)
handles.widgeRect(2) = handles.widgeRect(2) + handles.widgeRect(4);


% Create one or more row of widgets
% for each field of this dX___ object...
for n = 1:size(editAttrib,1)

    % ...organize info about this field of dX___:
    %   .name           ... string containing name of dX___ field
    %   .data           ... data in fieldname
    %   .safeType       ... string MATLAB class of data in fieldname
    %   .userType       ... string special flag or user-defined type of fieldname
    %   .range          ... cell containing constraints on field.data
    field.name      = editAttrib{n,1};
    field.data      = get(handles.dXcopy,field.name);
    field.safeType  = class(field.data);
    field.userType  = editAttrib(n,2);
    field.range     = editAttrib{n,3};

    % let callback assume field.range is a cell
    if ~isempty(field.range) && ~iscell(field.range)
        field.range = {field.range};
    end

    % ... make a text widget to show fieldname
    pos = handles.widgeRect;
    pos(3) = handles.tab(1) - 1;
    fnH = uicontrol(fig, ...
        'Style',                'text', ...
        'Position',             pos, ...
        'HorizontalAlignment',  'right', ...
        'String',               sprintf('%s =',field.name), ...
        'Tag',                  'fieldName');

    % ... make one or more groups of widgets
    %   appropriate for data of type safeType

    switch field.safeType

        case 'cell'

            % create a row of widgets that allows
            % addition and removal of cell elements

            % single-row edit field
            pos = handles.widgeRect;
            pos([1,3]) = [handles.tab(1), 12];
            arH = uicontrol(fig, ...
                'Style',                'edit', ...
                'Position',             pos, ...
                'HorizontalAlignment',  'left', ...
                'BackgroundColor',      [0.5, 0.8, 1], ...
                'Max',                  1, ...
                'Min',                  .1, ...
                'Tag',                  'cellAddRemoveEdit');

            % retool the cell's fieldname text widget
            set(fnH, ...
                'Style',        'pushbutton', ...
                'String',       [field.name, '{ +/- i }'], ...
                'HorizontalAlignment',  'center', ...
                'Tag',          'cellAddRemoveButton', ...
                'Callback',     {@dXobject_cellAddRemove, ...
                arH, handles.sbH, field, handles.dXcopy});

            % pressing [return] in edit box same as clicking button
            set(arH, 'Callback', get(fnH, 'Callback'));

            % move widgeRect up by one widget
            handles.widgeRect(2) = handles.widgeRect(2) + handles.widgeRect(4);

            % greate a row of widgets for each cell element
            for e = length(field.data):-1:1

                % make a little field struct, f
                f.name      = field.name;
                f.data      = field.data{e};
                f.safeType  = class(f.data);
                f.userType  = {field.safeType,e};
                f.range     = field.range;

                % make a text widget to describe f
                pos = handles.widgeRect;
                pos(3) = handles.tab(1) - 1;

                uicontrol(fig, ...
                    'Style',                'text', ...
                    'Position',             pos, ...
                    'HorizontalAlignment',  'right', ...
                    'String',               sprintf('%s{%d} =',f.name,e), ...
                    'Tag',                  'cellElementName');



                % make a widget to represent/edit f
                handles = dXobject_widgetByType(handles, f);
            end

        case 'struct'

            % create a row of widgets for each struct field
            fdnms = fieldnames(field.data);
            for fn = 1:length(fdnms)

                % make a little field struct, f
                f.name      = field.name;
                f.data      = field.data.(fdnms{fn});
                f.safeType  = class(f.data);
                f.userType  = {field.safeType,fdnms{fn}};
                f.range     = field.range;

                % make a text widget to describe f
                pos = handles.widgeRect;
                pos(3) = handles.tab(1) - 1;
                uicontrol(fig, ...
                    'Style',                'text', ...
                    'Position',             pos, ...
                    'HorizontalAlignment',  'right', ...
                    'String',               sprintf('%s.%s =',f.name,fdnms{fn}), ...
                    'Tag',                  'structFieldName');

                % make a widget to represent/edit f
                handles = dXobject_widgetByType(handles, f);
            end

        otherwise

            % make a widget for this datafield
            handles = dXobject_widgetByType(handles,field);

    end
end

% resize objectGUI figure to accomodate all widgets
pos = get(fig, 'Position');
pos(3:4) = handles.widgeRect([3,2]);
set(fig, 'Position', pos);

% keep dXobjectGUI current
guidata(fig, handles);