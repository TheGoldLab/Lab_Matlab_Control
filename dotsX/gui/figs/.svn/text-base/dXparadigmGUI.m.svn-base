function varargout = dXparadigmGUI(varargin)
% DXPARADIGMGUI M-file for dXparadigmGUI.fig
%      DXPARADIGMGUI, by itself, creates a new DXPARADIGMGUI or raises the existing
%      singleton*.
%
%      H = DXPARADIGMGUI returns the handle to a new DXPARADIGMGUI or the handle to
%      the existing singleton*.
%
%      DXPARADIGMGUI('CALLBACK',hObject,eventdata,handles,...) calls the local
%      function named CALLBACK in DXPARADIGMGUI.M with the given input arguments.
%
%      DXPARADIGMGUI('Property','Value',...) creates a new DXPARADIGMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dXparadigmGUI_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dXparadigmGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help dXparadigmGUI

% Last Modified by GUIDE v2.5 12-Jun-2006 17:28:41

% I hate this guide nonsense
global ROOT_STRUCT
if ~isfield(ROOT_STRUCT, 'dXparadigm')
    rInit('debug', 'dXparadigm');
end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dXparadigmGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @dXparadigmGUI_OutputFcn, ...
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


% --- Executes just before dXparadigmGUI is made visible.
function dXparadigmGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dXparadigmGUI (see VARARGIN)
global ROOT_STRUCT

% Choose default command line output for dXparadigmGUI
handles.output = hObject;

% handle task info controls by trial index
handles.taskInfoControls = [];

% a hack for sliders to avoid double-tapping...
handles.sliderHackDelay = .100;

% let dXparadigm know about this GUI
ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, 'paradigmGUI', true);

% controls to grey-out during an experiment
handles.runDisable = [ ...
        handles.moveSlider,
        handles.moveText,
        handles.addButton,
        handles.removeButton,
        handles.bonusMagnus,
        handles.screenText,
        handles.screenMode];

% if a dXparadigm is loaded, fill in this menu now.
%   also fill in when a task is added with button.
if isfield(ROOT_STRUCT, 'dXtask')
    %setup trialOrder drop menu here, before it's copied/reused
    set(handles.trialOrderMenu, ...
        'String',   ROOT_STRUCT.classes.dXtask.ranges.trialOrder);
end

% handle task info column headers
handles.taskHeaders = findobj( ...
    get(hObject, 'Children'), 'Tag', 'taskHeader');

% handle task info controls
% this is a prototype set of invisible uicontrols to setup, copy, not use
handles.taskInfo = findobj( get(hObject, 'Children'), ...
    'TooltipString', 'task info', 'Visible', 'off');

% can't call these from object create functions because dependent obj
% wouldn't exist yet.  OR CAN?????????
ROOT_doWrite_Callback(handles.ROOT_doWrite, [], handles);
FIRA_doWrite_Callback(handles.FIRA_doWrite, [], handles);
itiSlider_Callback(handles.itiSlider, [], handles);
set(handles.paradigmFigure, 'Name', rGet('dXparadigm', 1, 'name'));

% Update handles structure
guidata(hObject, handles);

% rebuild GUI task info controls
bonusMagnus_Callback(handles.bonusMagnus, [], handles);
handles = guidata(hObject);

% pass useful handles to main dXgui
if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure)
    otherHandles = guidata(ROOT_STRUCT.guiFigure);
    otherHandles.runDisable = [otherHandles.runDisable; handles.runDisable];
    otherHandles.paradigmFigure = hObject;

    % pass the refresh word to dXhistoryGUI
    if ~isempty(otherHandles.historyFigure)
        dXhistoryGUI;
    end
    
    guidata(ROOT_STRUCT.guiFigure, otherHandles);
end

% --- Outputs from this function are returned to the command line.
function varargout = dXparadigmGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% position dXparadigmGUI on the top right of the (secondary) display
set(hObject, 'Units', 'pixels');
pos = get(hObject,'Position');
screens = get(0,'MonitorPositions');
if size(screens,1) == 1

    % single display situation
    x = screens(1,3) - pos(3) - 1;
    y = screens(1,4) - pos(4) - 1;

elseif screens(1,1) > screens(2,1)
    
    % second display on the left
    x = -pos(3) - 1;
    y = max(screens(:,4)) - pos(4) - 1;

else

    % second display on the right
    x = screens(1,3) + screens(2,3) - pos(3) - 1;
    y = max(screens(:,4)) - pos(4) - 1;

end

% set position and convert to character units
pos(1:2) = [x,y];
set(hObject, 'Position', pos);
set(hObject, 'Units', 'characters');

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%-------CREATE FUNCTIONS-------%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%-------CREATE FUNCTIONS-------%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%-------CREATE FUNCTIONS-------%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function moveSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to moveSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isequal(get(hObject,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    set(hObject, 'Value', 0, 'UserData', GetSecs);

% --- Executes during object creation, after setting all properties.
function trialOrderMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialOrderMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % already setup in dXparadigmGUI_OpeningFcn

% --- Executes during object creation, after setting all properties.
function proportionSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to proportionSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isequal(get(hObject,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    data.thenTime = GetSecs;
    data.ptr = {};
    data.index = nan;
    data.text = nan;
    set(hObject, 'UserData', data);

% --- Executes during object creation, after setting all properties.
function blocksSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blocksSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isequal(get(hObject,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    data.thenTime = GetSecs;
    data.ptr = {};
    data.text = nan;
    set(hObject, 'UserData', data);

% --- Executes during object creation, after setting all properties.
function topTasksHeader_CreateFcn(hObject, eventdata, handles)
% hObject    handle to topTasksHeader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    set(hObject, 'String', rGet('dXparadigm', 1, 'name'));

% --- Executes during object creation, after setting all properties.
function screenMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to screenMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    global ROOT_STRUCT
    % setup all the menu items
    strings = ROOT_STRUCT.classes.dXparadigm.ranges.screenMode;
    set(hObject, 'String', strings);
    % pick the current one
    if isempty(eventdata)
        eventdata = get(ROOT_STRUCT.dXparadigm, 'screenMode');
    end
    nowVal  = find(strcmp(strings, eventdata));
	set(hObject, 'Value', nowVal);

% --- Executes during object creation, after setting all properties.
function taskOrder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to taskOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    global ROOT_STRUCT
    % setup all the menu items
    strings = ROOT_STRUCT.classes.dXparadigm.ranges.taskOrder;
    set(hObject, 'String', strings);
    % pick the current one
    if isempty(eventdata)
        eventdata = get(ROOT_STRUCT.dXparadigm, 'taskOrder');
    end
    nowVal  = find(strcmp(strings, eventdata));
	set(hObject, 'Value', nowVal);

% --- Executes during object creation, after setting all properties.
function fileSuffixMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileSuffixMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    global ROOT_STRUCT
    % setup all the menu items
    strings = ROOT_STRUCT.classes.dXparadigm.ranges.fileSuffixMode;
    set(hObject, 'String', strings);
    % pick the current one
    if isempty(eventdata)
        eventdata = get(ROOT_STRUCT.dXparadigm, 'fileSuffixMode');
    end
    nowVal  = find(strcmp(strings, eventdata));
	set(hObject, 'Value', nowVal);

% --- Executes during object creation, after setting all properties.
function itiSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to itiSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    set(hObject, 'Value', rGet('dXparadigm', 1, 'iti'));
    
    if isequal(get(hObject,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end
    
% --- Executes during object creation, after setting all properties.
function iti_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iti (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'iti');
    else
        % called by dXGUI_sync
        set(handles.itiSlider, 'Value', eventdata);
    end
    set(hObject, 'String', sprintf('iti = %1.1f sec', eventdata));

% --- Executes during object creation, after setting all properties.
function ROOT_filenameBase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROOT_filenameBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'ROOT_filenameBase');
    end
    set(hObject, 'String', eventdata);

% --- Executes during object creation, after setting all properties.
function ROOT_writeInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROOT_writeInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'ROOT_writeInterval');
    end
    set(hObject, 'String', eventdata);

% --- Executes during object creation, after setting all properties.
function ROOT_saveDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROOT_saveDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'ROOT_saveDir');
    end
    set(hObject, 'String', leftTruncate(hObject, eventdata));

% --- Executes during object creation, after setting all properties.
function ROOT_doWrite_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROOT_doWrite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'ROOT_doWrite');
    end
    set(hObject, 'Value', eventdata);

% --- Executes during object creation, after setting all properties.
function FIRA_filenameBase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FIRA_filenameBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'FIRA_filenameBase');
    end

    set(hObject, 'String', eventdata);

% --- Executes during object creation, after setting all properties.
function FIRA_writeInterval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FIRA_writeInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'FIRA_writeInterval');
    end
    set(hObject, 'String', eventdata);

% --- Executes during object creation, after setting all properties.
function FIRA_saveDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FIRA_saveDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'FIRA_saveDir');
    end
    set(hObject, 'String', leftTruncate(hObject, eventdata));

% --- Executes during object creation, after setting all properties.
function FIRA_doWrite_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FIRA_doWrite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'FIRA_doWrite');
    end
    set(hObject, 'Value', eventdata);

% --- Executes during object creation, after setting all properties.
function trialLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'trialLimit');
    end
    set(hObject, 'String', eventdata);
    
% --- Executes during object creation, after setting all properties.
function timeLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'timeLimit');
    end
    set(hObject, 'String', eventdata);

% --- Executes during object creation, after setting all properties.
function saveToFIRA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveToFIRA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'saveToFIRA');
    end
    set(hObject, 'Value', eventdata);

% --- Executes during object creation, after setting all properties.
function repeatAllTasksSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repeatAllTasksSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isequal(get(hObject,'BackgroundColor'), ...
            get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);1
    end
    set(hObject, 'Value', 0, 'UserData', GetSecs);

% --- Executes during object creation, after setting all properties.
function repeatAllTasks_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repeatAllTasks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'repeatAllTasks');
    end
    set(hObject, 'String', eventdata);

% --- Executes during object creation, after setting all properties.
function name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called%
% --- Executes during object creation, after setting all properties.
    if isempty(eventdata)
        eventdata = rGet('dXparadigm', 1, 'name');
    end
    set(hObject, 'String', eventdata);
    
    if isfield(handles, 'paradigmFigure') && ishandle(handles.paradigmFigure)
        set(handles.paradigmFigure, 'Name', eventdata);
    end

%%%%%%%%%%%%%%%%%%%%-------CALLBACKS-------%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%-------CALLBACKS-------%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%-------CALLBACKS-------%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in bonusMagnus.
function bonusMagnus_Callback(hObject, eventdata, handles)
% hObject    handle to bonusMagnus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT

    % remove any old taskInfo controls, but not the invisible prototypes
    delete(handles.taskInfoControls);
    handles.taskInfoControls = [];

    % reset rect that manages GUI real estate
    tipos = cell2mat(get(handles.taskInfo, 'Position'));
    handles.nextRow = [ ...
        min(tipos(:,1)), ...
        min(tipos(:,2)), ...
        max(tipos(:,1)) - min(tipos(:,1)) + 10, ...
        max(tipos(:,4))];

    % get real
    if isfield(ROOT_STRUCT, 'dXtask') && ~isempty(ROOT_STRUCT.dXtask)
    
        % grab info for all tasks
        taskCount = size(ROOT_STRUCT.dXtask, 2);
        taskPropo = get(ROOT_STRUCT.dXparadigm, 'taskProportions');

        % clip current task index to legal
        taski = max(get(ROOT_STRUCT.dXparadigm, 'taski'), 1);
        taski = min(taski, taskCount);
        ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, 'taski', taski);

        % zero-time marker for slider misbehavior hack-around
        data.thenTime = GetSecs;

        % I don't think there's repmat/vectorized copyobj.  So loop.
        % Loop backwards to give index #1 a leg up on the pile
        for t = taskCount:-1:1
            % copy make a row of task-related UI controls
            p = copyobj(handles.taskInfo, handles.paradigmFigure);
            
            % task info controls by trial index
            handles.taskInfoControls(t, :) = p;

            % make EZ-READ stripes
            if mod(t, 2)
                set(p, 'BackgroundColor', [1, 1, 1]*.5);
            end

            % Reposition row of controls above previous row,
            %   make them visible
            newpos = cell2mat(get(p, 'Position'));
            newpos(:,2) = handles.nextRow(2);
            set(p, ...
                {'Position'},   mat2cell(newpos, ones(1,size(newpos,1))), ...
                'Visible',      'on');

            % increment the GUI real estate rectangle
            handles.nextRow(2) = handles.nextRow(2) + handles.nextRow(4);

            % name the task index text
            set(findobj(p, 'Tag', 'taskIndex'), 'String', t);

            % name the task's toggle button and 
            % put the task index in unused field
            set(findobj(p, 'Tag', 'taskToggle'), ...
                'String',   get(ROOT_STRUCT.dXtask(t), 'name'), ...
                'UserData', t);

            % setup text and slider for task repetitions
            data.ptr = {'dXparadigm', 1, 'taskProportions'};
            data.index = t;
            data.text = findobj(p, 'Tag', 'proportionText');
            set(findobj(p, 'Tag', 'proportionSlider'), 'UserData', data);
            
            % setup trialOrder menu
            ptr = {'dXtask', t, 'trialOrder'};
            set(findobj(p, 'Tag', 'trialOrderMenu'), ...
                'UserData', ptr);

            % setup text and slider for block set size
            data.ptr = {'dXtask', t, 'blockReps'};
            data.text = findobj(p, 'Tag', 'blocksText');
            set(findobj(p, 'Tag', 'blocksSlider'), 'UserData', data);

            % setup reset button for this task
            set(findobj(p, 'Tag', 'resetButton'), 'UserData', t);

            % update task info control values
            updateTaskControls(t, handles, t==taski);
        end
    end

    % position the task info column headers above task info
    newpos = cell2mat(get(handles.taskHeaders, 'Position'));
    newpos(:,2) = handles.nextRow(2);
    set(handles.taskHeaders, ...
        {'Position'}, mat2cell(newpos, ones(1,size(newpos,1))));

    % position big "Tasks:" label at the very top
    newpos = get(handles.topTasksHeader, 'Position');
    newpos(:,2) = handles.nextRow(2) + 1.5*handles.nextRow(4);
    set(handles.topTasksHeader, 'Position', newpos);

    % resize figure to accomodate the everything
    newH = handles.nextRow(2) + 3*handles.nextRow(4);
    newpos = get(handles.paradigmFigure, 'Position');
    newpos(2) = newpos(2) - newH + newpos(4);
    newpos(4) = newH;
    set(handles.paradigmFigure, 'Position', newpos);

    % this is too damn easy to forget.
    guidata(hObject, handles);

    % Dear MATLAB: please be very lame.
    drawnow
    refresh(handles.paradigmFigure);

% --- Executes on selection change in trialOrderMenu.
function trialOrderMenu_Callback(hObject, eventdata, handles)
% hObject    handle to trialOrderMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    strns = get(hObject, 'String');
    val = strns{get(hObject, 'Value')};
    ptr = get(hObject, 'UserData');
    rSet(ptr{:}, val);

% --- Executes on slider movement.
function proportionSlider_Callback(hObject, eventdata, handles)
% hObject    handle to proportionSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    data = get(hObject, 'UserData');
    nowTime = GetSecs;

    % This is very lame:
    %   One mouse click on a slider button causes a double or triple callback.
    %   So, ignore repeated callbacks that are fewer than hundreds of ms apart.
    if nowTime - data.thenTime > handles.sliderHackDelay
        % actually do the callback

        propo = rGet(data.ptr{:});
        val = max(0, propo(data.index) + get(hObject, 'Value'));
        propo(data.index) = val;
        rSet(data.ptr{:}, propo);
        
        data.thenTime = nowTime;
        set(data.text, 'String', val);
        set(hObject, 'Value', 0, 'Userdata', data);
    else
        set(hObject, 'Value', 0);
    end

% --- Executes on slider movement.
function blocksSlider_Callback(hObject, eventdata, handles)
% hObject    handle to blocksSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    data = get(hObject, 'UserData');
    nowTime = GetSecs;

    % This is very lame:
    %   One mouse click on a slider button causes a double or triple callback.
    %   So, ignore repeated callbacks that are fewer than hundreds of ms apart.
    if nowTime - data.thenTime > handles.sliderHackDelay
        % actually do the callback

        val = max(1, rGet(data.ptr{:}) + get(hObject, 'Value'));

        data.thenTime = nowTime;

        rSet(data.ptr{:}, val);
        set(data.text, 'String', val);
        set(hObject, 'Value', 0, 'Userdata', data);
    else
        set(hObject, 'Value', 0);
    end

% --- Executes on button press in taskToggle.
function taskToggle_Callback(hObject, eventdata, handles)
% hObject    handle to taskToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % button groups are buggy and beyond lame.  Just manage all toggle buttons
    % with this one easy callback
    set(findobj('Tag', 'taskToggle'), 'Value', false);
    set(hObject, 'Value', true);
    % done.  Easy.  Chill out.

    % pass selection on to paradigm (sometimes redundntly: alas)
    rSet('dXparadigm', 1, 'taski', get(hObject, 'UserData'));

% --- Executes on button press in resetButton.
function resetButton_Callback(hObject, eventdata, handles)
% hObject    handle to resetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    t = get(hObject, 'UserData');
    if isfield(ROOT_STRUCT, 'dXtask') && ~isempty(ROOT_STRUCT.dXtask)
        % forced reset of this task
        ROOT_STRUCT.dXtask(t) = reset(ROOT_STRUCT.dXtask(t), true);
    end

function topTasksHeader_Callback(hObject, eventdata, handles)
% hObject    handle to topTasksHeader (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    name = get(hObject, 'String');
    set(handles.paradigmFigure, 'Name', name);
    rSet('dXparadigm', 1, 'name', name);
    editFlash(hObject, true);

% --- Executes on slider movement.
function moveSlider_Callback(hObject, eventdata, handles)
% hObject    handle to moveSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    % This is very lame:
    %   One mouse click on a slider button causes a double or triple callback.
    %   This is esp. huge problem when queueing graphics events, as here.
    %   So, ignore repeated callbacks that are fewer than hundreds of ms apart.
    nowTime = GetSecs;
    if nowTime - get(hObject, 'UserData') > handles.sliderHackDelay*3
        % actually do the callback

        % get real
        if ~isfield(ROOT_STRUCT, 'dXtask') || isempty(ROOT_STRUCT.dXtask)
            return
        end

        taskCount = size(ROOT_STRUCT.dXtask, 2);
        taski = get(ROOT_STRUCT.dXparadigm, 'taski');
        next = taski - get(hObject, 'Value');
        
        set(hObject, 'Value', 0, 'Userdata', nowTime);
        
        if next > 0 && next <= taskCount
            % if task name looks like dXparagidm.taskList(taski),
            % swap with dXparagidm.taskList(next)
            name = lower(get(ROOT_STRUCT.dXtask(taski), 'name'));
            tL = get(ROOT_STRUCT.dXparadigm, 'taskList');
            if any(strcmp(lower(tL{taski}), {name, ['task',name]}));
                tL([taski,next]) = tL([next,taski]);
            end
            
            % keep taskProportions sorted to match tasks themselves
            tP = get(ROOT_STRUCT.dXparadigm, 'taskProportions');
            tP([taski,next]) = tP([next,taski]);
            
            % update paradigm data
            rSet('dXparadigm', 1, ...
                'taskList', tL, ...
                'taskProportions', tP, ...
                'taski', next);

            % swap tasks in ROOT_STRUCT
            ROOT_STRUCT.dXtask([taski,next]) = ROOT_STRUCT.dXtask([next,taski]);

            % Explicitly swapping rows of task info controls is possible, but
            % why bother?  Just rebuild the task info controls alltogether.
            bonusMagnus_Callback(handles.paradigmFigure, [], handles);
        end
    else
        set(hObject, 'Value', 0);
    end

% --- Executes on button press in removeButton.
function removeButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    taski = get(ROOT_STRUCT.dXparadigm, 'taski');
    % if current task name corresponds to a script in dXparagidm.taskList,
    % remove that entry from the taskList
    if isfield(ROOT_STRUCT, 'dXtask') && ~isempty(ROOT_STRUCT.dXtask)

        % probably remove script from tasklist
        name = lower(get(ROOT_STRUCT.dXtask(taski), 'name'));
        tL = get(ROOT_STRUCT.dXparadigm, 'taskList');
        tL(strcmp(lower(tL), name)) = [];
        tL(strcmp(lower(tL), ['task',name])) = [];
        
        % remove element from taskProportions
        tP = get(ROOT_STRUCT.dXparadigm, 'taskProportions');
        tP(taski) = [];

        % shout it out
        rSet('dXparadigm', 1, 'taskList', tL, 'taskProportions', tP);

        % Take this task out of ROOT_STRUCT top level...
        %   Remove instance from master list?  Remove group?  Ask for trouble???
        %   Groups and tasks ARE separate concepts/implementations, so don't
        %   remove the group--even if it was created *by the task*.
        rRemove('dXtask', taski);

        % rebuild GUI task info controls
        bonusMagnus_Callback(handles.bonusMagnus, [], handles);
        handles = guidata(hObject);
        guidata(hObject, handles);

        if ~isempty(ROOT_STRUCT.guiFigure)
            %rebuild ROOT_STRUCT menu in dXGUI
            otherHandles = guidata(ROOT_STRUCT.guiFigure);
            delete(get(otherHandles.rootStructMenu,'Children'));
            otherHandles.pointer = {};
            dXROOT_makeMenu(otherHandles.rootStructMenu, ROOT_STRUCT, otherHandles);

            % pass the refresh word to dXhistoryGUI
            if ~isempty(otherHandles.historyFigure)
                dXhistoryGUI;
            end

            dXGUI_sync(otherHandles);
        end
    end

    % --- Executes on button press in addButton.
function addButton_Callback(hObject, eventdata, handles)
% hObject    handle to addButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % get a script from uigetfile
    suggestion = mfilename('fullpath');
    basei = strfind(suggestion,'/gui');
    suggestion = fullfile(suggestion(1:basei),'tasks/*.*');
    [files, path, filteri] = uigetfile('*.m','Choose task script(s)', ...
        suggestion, 'MultiSelect', 'on');
    
    % lettuce assume a cellery
    if ~isempty(files) && ~iscell(files)
        files = {files}
    end

    % trim the '.m' extension(s)
    % How to avoid lame loop?????
    for f = 1:size(files, 2)
        files{f} = files{f}(1:end-2);
    end

    % catch errors so that GUI doesn't lie
    try
        % execute the new taskScript, don't reinit.
        global ROOT_STRUCT
        ROOT_STRUCT.dXparadigm = loadTasks(ROOT_STRUCT.dXparadigm, files);
    catch
        evalin('base', 'e = lasterror');
        return
    end

    % append new script to tasklist, or insert itiSlider if current task's name
    % matches tasklist(current task index)
    tL = rGet('dXparadigm', 1, 'taskList');
    tL = cat(2, tL, files);
    rSet('dXparadigm', 1, 'taskList', tL);

    % setup trialOrder drop menu before it's copied/reused below
    if isfield(ROOT_STRUCT, 'dXtask')
        set(handles.trialOrderMenu, ...
            'String',   ROOT_STRUCT.classes.dXtask.ranges.trialOrder);
    end

    % rebuild GUI task info controls
    bonusMagnus_Callback(handles.bonusMagnus, [], handles);
    handles = guidata(hObject);

    if ~isempty(ROOT_STRUCT.guiFigure)
        % rebuild ROOT_STRUCT menu in dXGUI
        otherHandles = guidata(ROOT_STRUCT.guiFigure);
        delete(get(otherHandles.rootStructMenu,'Children'));
        otherHandles.pointer = {};
        dXROOT_makeMenu(otherHandles.rootStructMenu, ROOT_STRUCT, otherHandles);

        % pass the refresh word to dXhistoryGUI
        if ~isempty(otherHandles.historyFigure)
            dXhistoryGUI;
        end

        dXGUI_sync(otherHandles);
    end

    % --- Executes on selection change in screenMode.
    function screenMode_Callback(hObject, eventdata, handles)
        % hObject    handle to screenMode (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        strings = get(hObject, 'String');
        nowVal  = strings{get(hObject, 'Value')};
    rSet('dXparadigm', 1, 'screenMode', nowVal);
    
    % detect change and rInit?
    % delegate that to dXp/set?
    % delegate that to screen/set?
    % what's the deal with airline peanuts??

% --- Executes on selection change in taskOrder.
function taskOrder_Callback(hObject, eventdata, handles)
% hObject    handle to taskOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    strings = get(hObject, 'String');
    nowVal  = strings{get(hObject, 'Value')};
    rSet('dXparadigm', 1, 'taskOrder', nowVal);

% --- Executes on selection change in fileSuffixMode.
function fileSuffixMode_Callback(hObject, eventdata, handles)
% hObject    handle to fileSuffixMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    strings = get(hObject, 'String');
    nowVal  = strings{get(hObject, 'Value')};
    rSet('dXparadigm', 1, 'fileSuffixMode', nowVal);

% --- Executes on slider movement.
function itiSlider_Callback(hObject, eventdata, handles)
% hObject    handle to itiSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    newIti = get(hObject,'Value');
    set(handles.iti,'String',sprintf('iti = %1.1f sec',newIti));
    rSet('dXparadigm', 1, 'iti', newIti);

% --- Executes on button press in ROOT_saveDir.
function ROOT_saveDir_Callback(hObject, eventdata, handles)
% hObject    handle to ROOT_saveDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    name = rGet('dXparadigm', 1, 'name');
    newDir = uigetdir(rGet('dXparadigm', 1, 'ROOT_saveDir'), ...
        ['ROOT_STRUCT file location for ', name]);
    
    if ischar(newDir)
        rSet('dXparadigm', 1, 'ROOT_saveDir', newDir);
        set(hObject, 'String', leftTruncate(hObject, newDir));
    end

function ROOT_filenameBase_Callback(hObject, eventdata, handles)
% hObject    handle to ROOT_filenameBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rSet('dXparadigm', 1, 'ROOT_filenameBase', get(hObject, 'String'));
    editFlash(hObject, true);

% --- Executes on button press in ROOT_doWrite.
function ROOT_doWrite_Callback(hObject, eventdata, handles)
% hObject    handle to ROOT_doWrite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    doWrite = get(hObject, 'Value');
    rSet('dXparadigm', 1, 'ROOT_doWrite', doWrite);
    if doWrite
        set([handles.ROOT_writeInterval, handles.rootSecText], ...
            'ForegroundColor', [1,1,1]*.5);
    else
        set([handles.ROOT_writeInterval, handles.rootSecText], ...
            'ForegroundColor', 'k');
    end

function ROOT_writeInterval_Callback(hObject, eventdata, handles)
% hObject    handle to ROOT_writeInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    inDub = str2double(get(hObject, 'String'));
    isGood = ~isnan(inDub);
    if isGood
        rSet('dXparadigm', 1, 'ROOT_writeInterval', inDub);
    else
        set(hObject, ...
            'String', rGet('dXparadigm', 1, 'ROOT_writeInterval'));
    end
    editFlash(hObject, isGood);

% --- Executes on button press in FIRA_saveDir.
function FIRA_saveDir_Callback(hObject, eventdata, handles)
% hObject    handle to FIRA_saveDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    name = rGet('dXparadigm', 1, 'name');
    newDir = uigetdir(rGet('dXparadigm', 1, 'FIRA_saveDir'), ...
        ['FIRA file location for ', name]);
    
    if ischar(newDir)
        rSet('dXparadigm', 1, 'FIRA_saveDir', newDir);
        set(hObject, 'String', leftTruncate(hObject, newDir));
    end

% --- Executes on button press in FIRA_doWrite.
function FIRA_doWrite_Callback(hObject, eventdata, handles)
% hObject    handle to FIRA_doWrite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    doWrite = get(hObject, 'Value');
    rSet('dXparadigm', 1, 'FIRA_doWrite', doWrite);
    if doWrite
        set([handles.FIRA_writeInterval, handles.firaSecText], ...
            'ForegroundColor', [1,1,1]*.5);
    else
        set([handles.FIRA_writeInterval, handles.firaSecText], ...
            'ForegroundColor', 'k');
    end

function FIRA_writeInterval_Callback(hObject, eventdata, handles)
% hObject    handle to FIRA_writeInterval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    inDub = str2double(get(hObject, 'String'));
    isGood = ~isnan(inDub);
    if isGood
        rSet('dXparadigm', 1, 'FIRA_writeInterval', inDub);
    else
        set(hObject, ...
            'String', rGet('dXparadigm', 1, 'FIRA_writeInterval'));
    end
    editFlash(hObject, isGood);

function FIRA_filenameBase_Callback(hObject, eventdata, handles)
% hObject    handle to FIRA_filenameBase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rSet('dXparadigm', 1, 'FIRA_filenameBase', get(hObject, 'String'));
    editFlash(hObject, true);

function trialLimit_Callback(hObject, eventdata, handles)
% hObject    handle to trialLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    inDub = str2double(get(hObject, 'String'));
    isGood = ~isnan(inDub);
    if isGood
        rSet('dXparadigm', 1, 'trialLimit', inDub);
    else
        set(hObject, ...
            'String', rGet('dXparadigm', 1, 'trialLimit'));
    end
    editFlash(hObject, isGood);
    
function timeLimit_Callback(hObject, eventdata, handles)
% hObject    handle to timeLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    inDub = str2double(get(hObject, 'String'));
    isGood = ~isnan(inDub);
    if isGood
        rSet('dXparadigm', 1, 'timeLimit', inDub);
    else
        set(hObject, ...
            'String', rGet('dXparadigm', 1, 'timeLimit'));
    end
    editFlash(hObject, isGood);

% --- Executes on button press in saveToFIRA.
function saveToFIRA_Callback(hObject, eventdata, handles)
% hObject    handle to saveToFIRA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rSet('dXparadigm', 1, 'saveToFIRA', get(hObject, 'Value'));

% --- Executes on slider movement.
function repeatAllTasksSlider_Callback(hObject, eventdata, handles)
% hObject    handle to repeatAllTasksSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    % This is very lame:
    %   One mouse click on a slider button causes a double or triple callback.
    %   So, ignore repeated callbacks that are fewer than hundreds of ms apart.
    nowTime = GetSecs;
    if nowTime - get(hObject, 'UserData') > handles.sliderHackDelay
        % actually do the callback

        val = max(0, rGet('dXparadigm', 1, ...
            'repeatAllTasks') + get(hObject, 'Value'));

        rSet('dXparadigm', 1, 'repeatAllTasks', val);
        set(handles.repeatAllTasks, 'String', val);
        set(hObject, 'Value', 0, 'Userdata', nowTime);
    else
        set(hObject, 'Value', 0);
    end
    
% --- Executes on button press in infRepsToggle.
function infRepsToggle_Callback(hObject, eventdata, handles)
% hObject    handle to infRepsToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    if get(hObject, 'Value')
        % pressed it, go to repeat forever mode
        set(hObject, 'UserData', rGet('dXparadigm', 1, 'repeatAllTasks'));
        rSet('dXparadigm', 1, 'repeatAllTasks', inf);
        set(handles.repeatAllTasks, 'String', inf);
        set(handles.repeatAllTasksSlider, 'Enable', 'off');
    else
        % unpressed, return to normal mode
        val = get(hObject, 'UserData');
        rSet('dXparadigm', 1, 'repeatAllTasks', val);
        set(handles.repeatAllTasks, 'String', val);
        set(handles.repeatAllTasksSlider, 'Enable', 'on');
    end

function name_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    name = get(hObject, 'String');
    rSet('dXparadigm', 1, 'name', name);
    set(handles.paradigmFigure, 'Name', name);
    % do some kind of reality/legality check??
    editFlash(hObject, true);

%%%%%%%%%%%%%%%%%%%%-------OTHER FUNCTIONS-------%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%-------OTHER FUNCTIONS-------%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%-------OTHER FUNCTIONS-------%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object deletion, before destroying properties.
function paradigmFigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to paradigmFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    ROOT_STRUCT.dXparadigm = set(ROOT_STRUCT.dXparadigm, 'paradigmGUI', false);

    % remove these controls from the grey-out list of main GUI
    if ~isempty(ROOT_STRUCT) && ishandle(ROOT_STRUCT.guiFigure)
        otherHandles = guidata(ROOT_STRUCT.guiFigure);
        otherHandles.runDisable = otherHandles.runDisable ...
            (~ismember(otherHandles.runDisable, handles.runDisable));
        otherHandles.paradigmFigure = [];
        guidata(ROOT_STRUCT.guiFigure, otherHandles);
    end

% --- Gravy function for confirming/rejecting edit box input
function editFlash(hObject, isGood)
    if isGood
        set(hObject, 'BackgroundColor', 'b');
        drawnow
        set(hObject, 'BackgroundColor', 'w');
    else
        set(hObject, 'BackgroundColor', 'r');
        drawnow
        set(hObject, 'BackgroundColor', 'w');
    end
    
% --- Gravy function for LEFT truncating strings to fit in a uicontrol
function str_ = leftTruncate(hObject, str_)
        pos = get(hObject, 'Position');
        if str_(end) ~= '/';
            str_(end+1) = '/';
        end
        if length(str_) > pos(3) - 6
            str_ = ['...', str_(end+6-ceil(pos(3)):end)];
        end