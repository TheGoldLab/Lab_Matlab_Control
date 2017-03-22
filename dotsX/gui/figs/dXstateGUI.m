function varargout = dXstateGUI(varargin)
%DXSTATEGUI M-file for dXstateGUI.fig
%
% Not a command line or script GUI.  Used as callback for dXgui menu items.
%
% As a callback, varargin should look like:
%   {hObject, [], {pointer to dXstate instance}}

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @dXstateGUI_OpeningFcn, ...
    'gui_OutputFcn',  @dXstateGUI_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before dXstateGUI is made visible.
function dXstateGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% varargin{3} should be a task/group name
if size(varargin, 2) > 2 && ischar(varargin{3})
    global ROOT_STRUCT

    % show the states of which dXtask instance?
    handles.taskName = varargin{3};

    % coordinate with main dXgui, allow one instanve per task
    if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure)
        otherHandles = guidata(ROOT_STRUCT.guiFigure);
        if ~isempty(otherHandles.stateFigures.(handles.taskName))
            close(otherHandles.stateFigures.(handles.taskName))
        end
        otherHandles.stateFigures.(handles.taskName) = hObject;
        guidata(ROOT_STRUCT.guiFigure, otherHandles);
    end

    % get position info for organizing state data in rows and columns
    h = [handles.index, ...
        handles.name, ...
        handles.func, ...
        handles.args, ...
        handles.jump, ...
        handles.wait, ...
        handles.reps, ...
        handles.draw, ...
        handles.query, ...
        handles.cond];
    pos = cell2mat(get(h, 'Position'));

    % operate on one group only
    oldGroup = ROOT_STRUCT.groups.name;
    rGroup(handles.taskName);

    % all properties of all the dXstate objects in ROOT_STRUCT top level
    stateBook = struct(ROOT_STRUCT.dXstate);
    stateCount = size(stateBook,2);

    % dXstate props and gui widgets have the same names
    fieldList = cat(1, {'index'}, fieldnames(stateBook));
    fieldCount = size(h, 2);

    % precompute eZ2ReeD stripe pattern
    stripes = repmat([.6,.7], 1, stateCount);

    % edit properties of prototype uicontrols, copy them to organized
    % struct, make them visible
    for st = stateCount:-1:1
        
        % Crap McGee and do more later
        set(handles.index, 'String', st);

        set(handles.name, 'String', stateBook(st).name, ...
            'Callback', {@dXobjectGUI, {'dXstate', st}});

        if isempty(stateBook(st).func)
            str = 'none';
        else
            str = func2str(stateBook(st).func);
        end
        set(handles.func, 'String', str);

        if iscell(stateBook(st).args) && ~isempty(stateBook(st).args)
            stateBook(st).args = stateBook(st).args{1};
        end
        if isempty(stateBook(st).args)
            str = '()';
        else
            str = stateBook(st).args;
        end
        set(handles.args, 'String', str);

        set(handles.jump, 'String', stateBook(st).jump);

        set(handles.wait, 'String', stateBook(st).wait);

        set(handles.reps, 'String', stateBook(st).reps);

        set(handles.draw, 'String', stateBook(st).draw);

        if iscell(stateBook(st).query)
            stateBook(st).query = stateBook(st).query{1};
        end
        if isempty(stateBook(st).query)
            str = 'none';
        elseif stateBook(st).query == 0
            str = 'none';
        elseif stateBook(st).query == 1
            str = '|';
        else
            str = stateBook(st).query;
        end
        set(handles.query, 'String', str);

        if iscell(stateBook(st).cond) && ~isempty(stateBook(st).cond)
            stateBook(st).cond = stateBook(st).cond{1};
        end
        if isempty(stateBook(st).cond)
            str = 'none';
        else
            str = stateBook(st).cond;
        end
        set(handles.cond, 'String', str);

        % position the widgets atop older widgets
        set(h, {'Position'}, mat2cell(pos, ones(1,size(pos,1))), ...
            'BackgroundColor', [1,1,1]*stripes(st));
        pos(:,2) = pos(:,2) + pos(:,4);

        % remember always what we have made here together
        for f = 1:fieldCount;
            row.(fieldList{f}) = copyobj(handles.(fieldList{f}), hObject);
        end
        handles.rowBook(st) = row;
    end

    set(struct2array(handles.rowBook), 'Visible', 'on');

    % resize figure to accomodate all widgets, move to screen top right
    
    set(0, 'Units', 'characters');
    ss = get(0, 'ScreenSize');
    set(0, 'Units', 'pixels');
    height = max(pos(:,2));
    fp = get(hObject, 'Position');
    set(hObject, 'Position', [ss(3)-fp(3), ss(4)-fp(4), fp(3), height+0.5], ...
        'Name', ['states for task ', handles.taskName]);

    % repositon column headers at top of figure
    headPos = cell2mat(get(handles.columnHeader, 'Position'));
    headPos(:,2) = height + 0.5;
    set(handles.columnHeader, {'Position'}, ...
        mat2cell(headPos, ones(1,size(headPos,1))));

    % restore the previous group
    rGroup(oldGroup);
    
    handles.output = hObject;
else
    handles.output = -1;
    handles.taskName = [];
end

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = dXstateGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if handles.output == -1
        close(hObject)
    else
        varargout{1} = handles.output;
    end

% --- Executes during object deletion, before destroying properties.
function stateFigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to stateFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    % remove self from list of open figures
    if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure) && ~isempty(handles.taskName)
        otherHandles = guidata(ROOT_STRUCT.guiFigure);
        otherHandles.stateFigures.(handles.taskName) = [];
        guidata(ROOT_STRUCT.guiFigure, otherHandles);
    end