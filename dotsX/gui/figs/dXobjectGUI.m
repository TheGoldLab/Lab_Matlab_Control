function varargout = dXobjectGUI(varargin)
% DXOBJECTGUI M-file for dXobjectGUI.fig
%
% Not a command line or script GUI.  Used as callback for dXgui menu items.
%
% As a callback, varargin should look like:
%   {hObject, [], {pointer to dXsomething instance}}

% Last Modified by GUIDE v2.5 13-Jun-2006 17:13:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @dXobjectGUI_OpeningFcn, ...
    'gui_OutputFcn',  @dXobjectGUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
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


% --- Executes just before dXobjectGUI is made visible.
function dXobjectGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dXobjectGUI (see VARARGIN)

set(hObject,'Units','pixels');

global ROOT_STRUCT

% verify pointer argument
if size(varargin, 2) > 2 && iscell(varargin{3})

    % pull out pointer to dXsomething instance
    handles.pObject = varargin{3};
    
    % informative figure title, useful defaults
    namstr = sprintf('%s.',handles.pObject{1:end-1});
    namstr = sprintf('%s(%d)',namstr(1:end-1),handles.pObject{end});
    set(handles.objectFigure, ...
        'Name',                                 namstr, ...
        'Units',                                'characters', ...
        'DefaultUicontrolUnits',                'characters', ...
        'DefaultUicontrolFontUnits',            'points', ...
        'DefaultUicontrolFontSize',             10, ...
        'DefaultUicontrolMax',                  100, ...
        'DefaultUicontrolMin',                  0);

    % copy handles to figure data space
    guidata(hObject, handles)

    % make editing widgets.  This function will update handles.
    % pretend this is a callback from object [] and event []
    dXobject_makeWidgets([],[],hObject);

    % coordinate with main dXgui
    if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure)
        otherHandles = guidata(ROOT_STRUCT.guiFigure);

        % relocate objectGUI figure to manage screen realestate
        pos = get(hObject, 'Position');
        pos(1:2) = otherHandles.objFigPos(1:2)-[0,pos(4)];
        set(hObject, 'Position', pos);

        % increment screen location for next objectGUI figure
        otherHandles.objFigPos(1:2) = ...
            otherHandles.objFigPos(1:2) + [5,-1.7];

        % coordinate with main dXgui
        otherHandles.objectFigures = ...
            [otherHandles.objectFigures, hObject];

        % update dXgui mainFigure with figure information
        guidata(ROOT_STRUCT.guiFigure, otherHandles);
    end

    handles.output = hObject;

else
    handles.output = -1;
end

% final update of handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = dXobjectGUI_OutputFcn(hObject, eventdata, handles)
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
function objectFigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to objectFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    % remove self from list of open figures
    if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure)
        otherHandles = guidata(ROOT_STRUCT.guiFigure);
        otherHandles.objectFigures = otherHandles.objectFigures ...
            (otherHandles.objectFigures ~= hObject);
        guidata(ROOT_STRUCT.guiFigure, otherHandles);
    end