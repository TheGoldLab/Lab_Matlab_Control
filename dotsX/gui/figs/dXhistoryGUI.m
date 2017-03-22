function varargout = dXhistoryGUI(varargin)
% DXHISTORYGUI M-file for dXhistoryGUI.fig
%      DXHISTORYGUI, by itself, creates a new DXHISTORYGUI or raises the existing
%      singleton*.
%
%      H = DXHISTORYGUI returns the handle to a new DXHISTORYGUI or the handle to
%      the existing singleton*.
%
%      DXHISTORYGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DXHISTORYGUI.M with the given input arguments.
%
%      DXHISTORYGUI('Property','Value',...) creates a new DXHISTORYGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dXhistoryGUI_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dXhistoryGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help dXhistoryGUI

% Last Modified by GUIDE v2.5 27-Oct-2006 14:46:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dXhistoryGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @dXhistoryGUI_OutputFcn, ...
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


% --- Executes just before dXhistoryGUI is made visible.
function dXhistoryGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dXhistoryGUI (see VARARGIN)
    global ROOT_STRUCT

    set([handles.histList, handles.taskListHeader, handles.histListHeader], ...
        'String', trialSummary('taskname', '  #', ...
        '  #good(%)(#/min)', '  #correct(%)(#/min)', [], 'more'));

    set(handles.totalCheck, 'String', trialSummary('total', 0, 0, 0, 0));

    if ~isfield(handles, 'tasks')
        handles.tasks = [];
        handles.tasks.noName = [];
    end

    if ~isempty(ROOT_STRUCT)

        % build list of tasks with summary strings and check boxes
        bonusMagnus_Callback(handles.bonusMagnus, [], handles);
        handles = guidata(hObject);

        if ishandle(ROOT_STRUCT.guiFigure)
            % add self to list of open figures
            otherHandles = guidata(ROOT_STRUCT.guiFigure);
            otherHandles.historyFigure = hObject;
            guidata(ROOT_STRUCT.guiFigure, otherHandles);
        end
    end

    % Update handles structure
    handles.output = hObject;
    guidata(hObject, handles);

    % --- Outputs from this function are returned to the command line.
function varargout = dXhistoryGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% position dXhistoryGUI on the bottiom left of the (secondary) display
set(hObject, 'Units', 'pixels');
pos = get(hObject,'Position');
screens = get(0,'MonitorPositions');
if size(screens,1) == 1

    % single display situation
    x = 1;
    y = 1;

elseif screens(1,1) > screens(2,1)

    % second display on the left
    x = -screens(2,3) + 1;
    y = max(screens(:,4)) - screens(2,4) + 1;

else

    % second display on the right
    x = screens(1,3) + 1;
    y = max(screens(:,4)) - screens(2,4) + 1;

end

% set position and convert to character units
pos(1:2) = [x,y];
set(hObject, 'Position', pos);
set(hObject, 'Units', 'characters');

% Update handles structure
handles.output = hObject;
guidata(hObject, handles);

varargout{1} = handles.output;

% --- Executes during object deletion, before destroying properties.
function trialHistoryFigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to trialHistoryFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT
    if ~isempty(ROOT_STRUCT) 
        % remove self from list of open figures
        if ishandle(ROOT_STRUCT.guiFigure)
            otherHandles = guidata(ROOT_STRUCT.guiFigure);
            otherHandles.historyFigure = [];
            set(otherHandles.showHistoryCheck, 'Value', false);
            guidata(ROOT_STRUCT.guiFigure, otherHandles);
        end
    end
    
% --- Executes on button press in totalCheck.
function totalCheck_Callback(hObject, eventdata, handles)
% hObject    handle to totalCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rSet('dXparadigm', 1, 'showFeedback', get(hObject, 'Value'));

% --- Executes on button press in totalCheck.
function taskCheck_Callback(hObject, eventdata, handles)
% hObject    handle to totalCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    rSetTaskByName(get(hObject, 'UserData'), ...
        'showFeedback', get(hObject, 'Value'));

% --- Executes on button press in totalFeedbackCheck.
function totalFeedbackCheck_Callback(hObject, eventdata, handles)
% hObject    handle to totalFeedbackCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    fs = rGet('dXparadigm', 1, 'feedbackSelect');
    fs.(get(hObject, 'TooltipString')) = get(hObject, 'Value');
    rSet('dXparadigm', 1, 'feedbackSelect', fs);
    
% --- Executes on button press in taskFeedbackCheck.
function taskFeedbackCheck_Callback(hObject, eventdata, handles)
% hObject    handle to taskFeedbackCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    taskBook = rGet('dXtask');
    taskSelect = [taskBook.feedbackSelect];
    
    % set all tasks to show/not show this feedback datum.
    %   otherwise impossible to know which boxes to check
    [taskSelect.(get(hObject, 'TooltipString'))] = deal(get(hObject, 'Value'));
    
    % can only set one task at a time
    for t = 1:length(taskBook)
        rSet('dXtask', t, 'feedbackSelect', taskSelect(t));
    end

% --- Executes on button press in bonusMagnus.
function bonusMagnus_Callback(hObject, eventdata, handles)
% hObject    handle to bonusMagnus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global ROOT_STRUCT

    % remove any old task summary checkboxes
    taskHandles = struct2array(handles.tasks);
    if ~isempty(taskHandles)
        delete(taskHandles);
        handles.tasks = [];
        handles.tasks.noName = [];
    end

    % reset rect that manages GUI real estate
    tipos = get(handles.totalCheck, 'Position');
    handles.nextRow = tipos.*[1,1,1,1.55]+[0,1.55*tipos(4),0,0];

    % get real
    if isfield(ROOT_STRUCT, 'dXtask') && ~isempty(ROOT_STRUCT.dXtask)

        % grab info for all tasks
        taskBook = struct(ROOT_STRUCT.dXtask);
        taskCount = size(taskBook, 2);

        % grab info for paradigm
        dXp = struct(ROOT_STRUCT.dXparadigm);

        % use the same 'now' time for all statistics
        totalClock = clock - dXp.sessionTime;
        totalMins = sum(totalClock(4:6).*[60, 1, 1/60]);

        % update totals text, with data from dXparadigm
        set(handles.totalCheck, ...
            'Value',    get(ROOT_STRUCT.dXparadigm(1), 'showFeedback'), ...
            'String',   trialSummary( 'total', dXp.totalTrials, ...
            dXp.goodTrials, dXp.correctTrials, totalMins, dXp.moreFeedback));

        % BSH doesn't think there's repmat/vectorized copyobj.  So loop.
        % Loop backwards to give #1 indexed dXtask a leg up on the pile
        for t = taskCount:-1:1

            % grab info for this task
            task = taskBook(t);

            % copy make a row of task-related UI controls
            p = copyobj(handles.totalCheck, handles.trialHistoryFigure);

            % make EZ-READ stripes
            if mod(t, 2)
                c = [.3, .8, .8];
            else
                c = [.8, .5, .8];
            end
            set(p, 'BackgroundColor', c);

            % Reposition summary for this task above previous summary
            %   put task name in userdata
            %   retag them as 'task', not 'total'
            newpos = get(p, 'Position');
            newpos(2) = handles.nextRow(2);
            set(p, 'UserData', task.name, 'Position', newpos);

            % 'customize' the feedback for this task
            taskMins = (GetSecs-task.startTime)/60;
            set(p, ...
                'Tag',      'taskCheck', ...
                'Value',    task.showFeedback, ...
                'Callback', @taskCheck_Callback, ...
                'String', 	trialSummary( ...
                task.name, task.totalTrials, task.goodTrials, ...
                task.correctTrials, taskMins, task.moreFeedback));

            % keep task performance summaries by task name
            if ~isempty(task.name) && ischar(task.name)
                handles.tasks.(task.name) = p;
            else
                handles.tasks.noName = ...
                    [handles.tasks.noName, p];
            end

            % increment the GUI real estate rectangle
            handles.nextRow(2) = handles.nextRow(2) + handles.nextRow(4);
        end
    end
    
    % position the task list header above task list
    newpos = get(handles.taskListHeader, 'Position');
    newpos(2) = handles.nextRow(2);
    set(handles.taskListHeader, 'Position', newpos);

    % increment the GUI real estate rectangle
    handles.nextRow(2) = handles.nextRow(2) + handles.nextRow(4);

    % position the task feedback selection checks above task info
    newpos = cell2mat(get(handles.taskFeedbackCheck, 'Position'));
    newpos(:,2) = handles.nextRow(2);
    set(handles.taskFeedbackCheck, ...
        {'Position'}, mat2cell(newpos, ones(1,size(newpos,1))));

    % position big header at the very top
    newpos = get(handles.topHeader, 'Position');
    newpos(:,2) = handles.nextRow(2) + handles.nextRow(4);
    set(handles.topHeader, 'Position', newpos);

    % resize figure to accomodate the everything
    newpos = get(handles.trialHistoryFigure, 'Position');
    newpos(4) = handles.nextRow(2) + 2.2*handles.nextRow(4);
    set(handles.trialHistoryFigure, 'Position', newpos);
    
    guidata(hObject, handles);

    % Dear MATLAB: please be very lame.
    drawnow
    refresh(handles.trialHistoryFigure);