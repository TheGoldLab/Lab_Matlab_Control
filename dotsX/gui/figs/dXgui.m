function varargout = dXgui(varargin)
%DXGUI M-file for dXgui.fig
%
%      DXGUI, by itself, creates a new DXGUI or raises the existing
%      singleton*.
%
%      H = DXGUI returns the handle to a new DXGUI or the handle to
%      the existing singleton*.
%
%      DXGUI('Property','Value',...) creates a new DXGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to dXgui_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      DXGUI('CALLBACK') and DXGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in DXGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help dXgui

% Last Modified by GUIDE v2.5 12-Nov-2008 18:18:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @dXgui_OpeningFcn, ...
    'gui_OutputFcn',  @dXgui_OutputFcn, ...
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


% --- Executes just before dXgui is made visible.
function dXgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)
global ROOT_STRUCT FIRA

% cleanup old stuff?
if any(isfield(handles, {'paradigmFigure', 'historyFigure'}));
    mainFigure_DeleteFcn(hObject, [], handles);
end

% gather handles of widgets to dis/enable with pauseToggle button
handles.runDisable = [ ...
    handles.sendMsgEdit,
    handles.rootStructMenu,
    handles.fileMenu];

% gather handles of widgets to dis/enable on startup/clearing/loading
handles.generalDisable = [ ...
    handles.stopToggle,
    handles.startToggle,
    handles.pauseToggle,
    handles.writeROOTButton,
    handles.writeFIRAButton];

% keep track of figures onscreen
handles.mainFigure = hObject;
handles.paradigmFigure = [];
handles.historyFigure = [];

% start out with limited GUI, until loadRoot or new
set(handles.generalDisable, 'Enable', 'off');

% clean out the ol' ROOT menu
delete(get(handles.rootStructMenu,'Children'));
handles.pointer = {};

% Choose default command line output for dXgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = dXgui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% position dXgui on the top left of the (secondary) display
    set(hObject, 'Units', 'pixels');
    pos = get(hObject,'Position');
    screens = get(0,'MonitorPositions');
    if size(screens,1) == 1

        % single display situation
        x = 1;
        y = screens(1,4) - pos(4) - 1;

    elseif screens(1,1) > screens(2,1)

        % second display on the left
        x = -screens(2,3)+1;
        y = max(screens(:,4)) - pos(4) - 1;

    else

        % second display on the right
        x = screens(1,3)+1;
        y = max(screens(:,4)) - pos(4) - 1;

    end

    % set position and convert to character units
    pos(1:2) = [x,y];
    set(hObject, 'Position', pos);
    set(hObject, 'Units', 'characters');
    pos = get(hObject, 'Position');

    % pick the correct output argument--the figure handle
    varargout{1} = handles.output;
    
    % steal time to actually show the GUI
    drawnow;

% MENU CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MENU CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MENU CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --------------------------------------------------------------------
function refreshRootStructMenu_Callback(hObject, eventdata, handles)
% hObject    handle to refreshRootStructMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT

    % generate fresh menu for all the fields of ROOT_STRUCT
    delete(get(handles.rootStructMenu,'Children'));
    handles.pointer = {};
    disp('scanning ROOT_STRUCT...')
    dXROOT_makeMenu(handles.rootStructMenu, ROOT_STRUCT, handles)
    disp('...done scanning')

% --------------------------------------------------------------------
function new_Callback(hObject, eventdata, handles)
% hObject    handle to new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT FIRA

    % write/clear old ROOT, FIRA
    try
        dXwriteExisting(2,2);
    catch
        return
    end
    ROOT_STRUCT = [];
    FIRA = [];
    delete(get(handles.rootStructMenu,'Children'));
    handles.pointer = {};

    % init debuggingly
    rInit('debug','dXudp','dXparadigm');
    sendMsg('%%%');

    % dXgui computer never uses 'local' mode
    if isempty(getMsg(1000))
        rRemove('dXudp');
        ROOT_STRUCT = rmfield(ROOT_STRUCT, 'socketNumber');
        rSet('dXparadigm',  1, 'screenMode', 'debug');
    else
        rInit('remote','dXparadigm', {'screenMode', 'remote'});
    end
    
    % do the nice GUI things with stuff
    ROOT_STRUCT.guiFigure = handles.mainFigure;
    if get(handles.showParaCheck, 'Value')
        dXparadigmGUI;
    end
    if get(handles.showHistoryCheck, 'Value')
        dXhistoryGUI;
    end
    set(handles.generalDisable, 'Enable', 'on');
    set(handles.pauseToggle, 'Enable', 'off');
    dXGUI_sync(handles);

% --------------------------------------------------------------------
function loadRoot_Callback(hObject, eventdata, handles)
% hObject    handle to loadRoot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global ROOT_STRUCT
    
    suggestion = mfilename('fullpath');
    basei = strfind(suggestion,'/gui');
    suggestion = [suggestion(1:basei),'/tasks/*.*'];
    [file, path, filteri] = ...
        uigetfile('*.mat', 'Load a paradigm root file', suggestion);
    
    if file == 0
        return
    end

    % load .mat datafile from it's own directory
    disp(['LOADING ',file]);
    load(fullfile(path,file));

    if ~isempty(ROOT_STRUCT)

        ROOT_STRUCT.guiFigure = handles.mainFigure;

        % restart HIDx
        ROOT_STRUCT.HIDxInit = HIDx('init');

        % activate root classes
        if isfield(ROOT_STRUCT.methods, 'root')
            rooty = ROOT_STRUCT.methods.root;

            % activate dXudp and dXscreen first
            s = strcmp(rooty, 'dXscreen');
            rooty = cat(2, rooty(s), rooty(~s));
            u = strcmp(rooty, 'dXudp');
            rooty = cat(2, rooty(u), rooty(~u));

            for rt = rooty
                ROOT_STRUCT.(rt{1}) = root(ROOT_STRUCT.(rt{1}));
            end
        end

        % setup remote drawing
        if ROOT_STRUCT.screenMode == 2
            % Add graphics to the remote machine.
            rRemoteAddGroups;
        end

        if isfield(ROOT_STRUCT,'dXparadigm')

            % these uicontrols rely on a dXparadigm
            set(handles.generalDisable, 'Enable', 'on');

            % initial setup on buttons/widgets
            set(handles.pauseToggle, 'Value', 0);

            % show me the gui (for the dXparadigm)
            if get(handles.showParaCheck, 'Value')
                guidata(hObject, handles);
                dXparadigmGUI;
                handles = guidata(hObject);
            end

            % show me the gui (for the history of trials)
            if get(handles.showHistoryCheck, 'Value')
                guidata(hObject, handles);
                dXhistoryGUI;
                handles = guidata(hObject);
            end
            dXGUI_sync(handles);
        end
    end

    % POPULATE 'ROOT_STRUCT' MENU
    if ~isempty(ROOT_STRUCT)
        delete(get(handles.rootStructMenu,'Children'));
        handles.pointer = {};
        guidata(hObject, handles);
    end

% --------------------------------------------------------------------
function runScript_Callback(hObject, eventdata, handles)
% hObject    handle to runScript (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    
    suggestion = mfilename('fullpath');
    basei = strfind(suggestion,'/gui');
    suggestion = [suggestion(1:basei),'/*.*'];
    [file, path, filteri] = ...
        uigetfile('*.m', 'Select a script to run', suggestion);
    
    if file == 0
        return
    end

    % run .m script from it's own directory
    disp(['RUNNING ',file]);
    run(fullfile(path,file));

    % POPULATE 'ROOT_STRUCT' MENU
    if ~isempty(ROOT_STRUCT)
        delete(get(handles.rootStructMenu,'Children'));
        handles.pointer = {};
        guidata(hObject, handles);
    end

% --------------------------------------------------------------------
function fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function rootStructMenu_Callback(hObject, eventdata, handles)
% hObject    handle to rootStructMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% BUTTON/WIDGET CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUTTON/WIDGET CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUTTON/WIDGET CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sendMsgEdit_Callback(hObject, eventdata, handles)
% hObject    handle to sendMsgEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT

    % check whether a message can be sent and whether this is a good time
    if ~isfield(ROOT_STRUCT,'socketNumber') || ROOT_STRUCT.socketNumber <= 0
        set(hObject, ...
            'String', 'client is not connected', ...
            'ForegroundColor', [1,1,1]*.5);
    else
        str = get(hObject,'String');
        if ~isempty(str) && ischar(str)
            sendMsgH(str);
        end
        set(hObject, 'ForegroundColor', [0,0,0]);
    end

% --- Executes on button press in writeFIRAButton.
function writeFIRAButton_Callback(hObject, eventdata, handles)
% hObject    handle to writeFIRAButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    dXwriteExisting(0,1);

    % --------------------------------------------------------------------
function writeROOT_Callback(hObject, eventdata, handles)
% hObject    handle to writeROOT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    dXwriteExisting(1,0);

% --- Executes on button press in writeROOTButton.
function writeROOTButton_Callback(hObject, eventdata, handles)
% hObject    handle to writeROOTButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    dXwriteExisting(1,0); % 0 = save ROOT_STRUCT without prompt, 0 = skip FIRA

% --- Executes on button press in startToggle.
function startToggle_Callback(hObject, eventdata, handles)
% hObject    handle to startToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT

    if get(hObject,'Value') ...
            && isfield(ROOT_STRUCT, 'dXparadigm') ...
            && ~isempty(ROOT_STRUCT.dXparadigm)

        % Starterup
        set(hObject, 'String', 'Running', 'Enable', 'off');
        set(handles.runDisable,'Enable','off');
        set(handles.pauseToggle, 'Enable', 'on');

        % do it to it!
        try
            runTasks(ROOT_STRUCT.dXparadigm);
            disp('Paradigm is done')
        catch
            disp('Paradigm has quit:')
            evalin('base', 'e = lasterror')
        end

        set(hObject, ...
            'String', 'start', ...
            'Enable', 'on', ...
            'Value', false);
        set(handles.runDisable,'Enable','on');
        set(handles.pauseToggle, 'Enable', 'off');
    else
        disp('There are no tasks to run.')
        set(hObject, 'String', '----');
        drawnow
        WaitSecs(.25);
        set(hObject, 'String', 'start', 'Value', false);
    end

% --- Executes on button press in stopToggle.
function stopToggle_Callback(hObject, eventdata, handles)
% hObject    handle to stopToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % this 'callback' goes in dXGUI_sync, where it may influence the main
    % flow of control.  MATLAB's handling of asynchronous events is lame.

% --- Executes on button press in pauseToggle.
function pauseToggle_Callback(hObject, eventdata, handles)
% hObject    handle to pauseToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % this 'callback' goes in dXGUI_sync, where it may influence the main
    % flow of control.  MATLAB's handling of asynchronous events is lame.

% --- Executes on button press in showParaCheck.
function showParaCheck_Callback(hObject, eventdata, handles)
% hObject    handle to showParaCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if get(hObject, 'Value')
        % checked = show dXparadigmGUI
        global ROOT_STRUCT
        if isempty(handles.paradigmFigure) ...
                && isfield(ROOT_STRUCT, 'dXparadigm')
            dXparadigmGUI;
        end
    else
        % unchecked = don't show dXparadigmGUI
        if ishandle(handles.paradigmFigure)
            close(handles.paradigmFigure);
        end
    end

% --- Executes during object creation, after setting all properties.
function showHistoryCheck_CreateFcn(hObject, eventdata, handles)
% hObject    handle to showHistoryCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in showHistoryCheck.
function showHistoryCheck_Callback(hObject, eventdata, handles)
% hObject    handle to showHistoryCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if get(hObject, 'Value')
        
        if isempty(handles.historyFigure) || ~ishandle(handles.historyFigure)
        % checked = show historyFigure
        dXhistoryGUI;
        end
    else
        % unchecked = don't show historyFigure
        if ishandle(handles.historyFigure)
            close(handles.historyFigure);
        end
    end

% --- Executes during object deletion, before destroying properties.
function mainFigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to mainFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT

    % guide is such a beach
    if ~isempty(handles)

        % close subordinate GUI figures
        figs = [handles.paradigmFigure, handles.historyFigure];
        delete(figs(ishandle(figs)));
    end

    if ~isempty(ROOT_STRUCT)
        % gui has left the building.
        ROOT_STRUCT.guiFigure = nan;
        rDone;
    end