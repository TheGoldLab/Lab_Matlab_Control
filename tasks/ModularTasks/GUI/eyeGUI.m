function varargout = eyeGUI(varargin)
% EYEGUI MATLAB code for eyeGUI.fig
%      EYEGUI, by itself, creates a new EYEGUI or raises the existing
%      singleton*.
%
%      H = EYEGUI returns the handle to a new EYEGUI or the handle to
%      the existing singleton*.
%
%      EYEGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EYEGUI.M with the given input arguments.
%
%      EYEGUI('Property','Value',...) creates a new EYEGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before eyeGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to eyeGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help eyeGUI

% Last Modified by GUIDE v2.5 13-Jun-2018 10:44:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @eyeGUI_OpeningFcn, ...
   'gui_OutputFcn',  @eyeGUI_OutputFcn, ...
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

% --- Executes just before eyeGUI is made visible.
function eyeGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to eyeGUI (see VARARGIN)

% Choose default command line output for eyeGUI
handles.output = hObject;

% First (required) arg is topsTreeNode
handles.topsTreeNode = varargin{1};
handles.task = [];

% Second (optional) arg is dotsReadable object
handles.readableEye = [];
if nargin > 4 && ~isempty(varargin{2}) && isa(varargin{2}, 'dotsReadableEye')
   handles.readableEye = varargin{2};
   handles.readableEye.openGazeMonitor(handles.gazeAxes);
end

% Run status args
handles.isRunning = false;

% Set other buttons as inactive
set([handles.skipbutton, handles.abortbutton, handles.recalibratebutton, ...
   handles.upbutton, handles.downbutton, ...
   handles.leftbutton, handles.rightbutton], ...
   'Enable', 'off');

% Update handles structure
guidata(hObject, handles);

% Task-specific updates
eyeGUI_updateTask(hObject, [], handles, []);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using eyeGUI.
if strcmp(get(hObject,'Visible'),'off') && isempty(handles.readableEye)
   % Create a grid of x and y data
   y = -10:0.5:10;
   x = -10:0.5:10;
   [X, Y] = meshgrid(x, y);
   
   % Create the function values for Z = f(X,Y)
   Z = sin(sqrt(X.^2+Y.^2)) ./ sqrt(X.^2+Y.^2);
   
   % Create a surface contour plor using the surfc function
   surfc(X, Y, Z);
   
   % Adjust the view angle
   view(-38, 18);
   
   % Add title and axis labels
   xlabel('x');
   ylabel('y');
   zlabel('z');
end

% UIWAIT makes eyeGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% ---- Call when incrementing tasks
%
function eyeGUI_updateTask(hObject, eventdata, handles, task)

% Add task
handles.task = task;

% update the text
text1_str = 'TASKS:';
for ii = 1:length(handles.topsTreeNode.children)
   text1_str = cat(2, text1_str, sprintf('  %d. %s', ...
      ii, handles.topsTreeNode.children{ii}.name));
   if ~isempty(task) && task==handles.topsTreeNode.children{ii}
      text1_str = cat(2, text1_str, '**');
   end
end
set(handles.status1text, 'String', text1_str);

% update the gazeWindow information
if ~isempty(handles.readableEye)
   
   % Configure the text boxes
   for ii = 1:4
      
      % active
      if ~isempty(task) && ii <= length(task.readables.dotsReadableEye)
         
         % Check radio button to see if value remains fixed across tasks
         fixedValue = get(handles.(sprintf('gw%dbutton', ii)), 'Value');
         
         % Both boxes
         for tags = {'Size' 'Dur'}
            h = handles.(sprintf('gw%d%s', ii, tags{:}));
            set(h, 'Enable', 'on');
            val = get(h, 'String');
            if isempty(val) || ~fixedValue
               set(h, 'String', num2str(...
                  task.readables.dotsReadableEye(ii).(sprintf('window%s', tags{:}))));
            elseif ~isempty(val) && fixedValue
               task.readables.dotsReadableEye(ii).(sprintf('window%s', tags{:})) = ...
                  num2str(val);
            end
         end
      else
         % Inactivate remaining boxes
         for tags = {'Size' 'Dur'}
            h = handles.(sprintf('gw%d%s', ii, tags{:}));
            set(h, 'Enable', 'off');
         end
      end
   end
end

% Make sure the GUI is updated
drawnow

% resave the data
guidata(hObject, handles);


% ---- Call when updating the gui within a task
%
function eyeGUI_updateTaskStatus(hObject, eventdata, handles, task, indices)

% Set the status strings
if any(indices==1)
   set(handles.status2text, 'String', task.statusStrings{1});
end
if any(indices==2)
   set(handles.status3text, 'String', task.statusStrings{2});
end
drawnow;

% % ---- Call when incrementing trials
% %
% function taskGUI_updateTrial(hObject, eventdata, handles, str1, str2)
%
% % possibly update the gaze windows
% if ~isempty(handles.readableEye)
%    for ii = 1:4
%
%       if length(handles.readableEye.gazeEvents) >= ii
%          diamStr = num2str(handles.readableEye.gazeEvents(ii).windowSize);
%          durStr  = num2str(handles.readableEye.gazeEvents(ii).windowDur);
%          enable = 'on';
%       else
%          diamStr = '';
%          durStr  = '';
%          enable  = 'off';
%       end
%
%       % Set diameter/dur in gui
%       set(handles.(sprintf('gwdiam%d', ii)), 'String', diamStr, 'Enable', enable);
%       set(handles.(sprintf('gwdur%d',  ii)), 'String', durStr,  'Enable', enable);
%    end
% end
%
% % resave the data
% guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = eyeGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
   open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
   ['Close ' get(handles.figure1,'Name') '...'],...
   'Yes','No','Yes');
if strcmp(selection,'No')
   return;
end

delete(handles.figure1)

% --- Executes on button press in startbutton.
function startbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check status
if ~handles.isRunning
   
   % Green with envy
   set(hObject, 'String', 'Running', ...
      'BackGroundColor', [0 1 0]);
   
   % Set other buttons as active
   if ~isempty(handles.readableEye)
      
      % recalibrate
      set(handles.recalibratebutton, 'Enable', 'on', ...
         'BackGroundColor', [1 1 0]);
      
      % offsets
      set([handles.upbutton, handles.downbutton, ...
         handles.leftbutton, handles.rightbutton], ...
         'Enable', 'on');
   end
   
   set(handles.skipbutton, 'Enable', 'on', ...
      'BackGroundColor', [1 0.5 0]);
   set(handles.abortbutton, 'Enable', 'on', ...
      'BackGroundColor', [1 0 0]);
   
   % Set the flag
   handles.isRunning = true;
   
   % Save the handles data
   guidata(hObject, handles);
   
   % Run the task
   handles.topsTreeNode.run();
   
   % Return when done
   return
end

% Toggle flag
handles.topsTreeNode.controlFlags.pause = ~handles.topsTreeNode.controlFlags.pause;

% Paused!
if handles.topsTreeNode.controlFlags.pause
   
   % Set appearance
   set(hObject, 'String', 'Paused', ...
      'BackGroundColor', [0.9 1.0 0.9]);
   drawnow;
   
   if ~handles.topsTreeNode.isRunning
      while handles.topsTreeNode.controlFlags.pause
         pause(0.01);
         handles = guidata(hObject);
      end
      return
   end
else
   
   % Unset paused flag and save
   set(hObject, 'String', 'Running', ...
      'BackGroundColor', [0 1 0]);
   drawnow;
end

% --- Executes on button press in skipbutton.
function skipbutton_Callback(hObject, eventdata, handles)
% hObject    handle to skipbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.topsTreeNode.controlFlags.skip = true;

% --- Executes on button press in abortbutton.
function abortbutton_Callback(hObject, eventdata, handles)
% hObject    handle to abortbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.isRunning = false;
guidata(hObject, handles);

if ~handles.topsTreeNode.isRunning
   % Abort now
   error('Aborting early!')
else
   % Wait until end of trial
   handles.topsTreeNode.controlFlags.abort = true;
end

% --- Executes on button press in recalibratebutton.
function recalibratebutton_Callback(hObject, eventdata, handles)
% hObject    handle to recalibratebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Send a handle to the object to calibrate
handles.topsTreeNode.controlFlags.calibrate = handles.readableEye;

% --- Executes on button press in upbutton.
function upbutton_Callback(hObject, eventdata, handles)
% hObject    handle to upbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.readableEye.incrementCalibrationOffsetY(0.1);

% --- Executes on button press in downbutton.
function downbutton_Callback(hObject, eventdata, handles)
% hObject    handle to downbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.readableEye.incrementCalibrationOffsetY(-0.1);

% --- Executes on button press in leftbutton.
function leftbutton_Callback(hObject, eventdata, handles)
% hObject    handle to leftbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.readableEye.incrementCalibrationOffsetX(-0.1);

% --- Executes on button press in rightbutton.
function rightbutton_Callback(hObject, eventdata, handles)
% hObject    handle to rightbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.readableEye.incrementCalibrationOffsetX(0.1);

function gw1Size_Callback(hObject, eventdata, handles)
% hObject    handle to gw1Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw1Size as text
%        str2double(get(hObject,'String')) returns contents of gw1Size as a double
handles.task.readables.dotsReadableEye(1).windowSize = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw1Size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw1Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw1Dur_Callback(hObject, eventdata, handles)
% hObject    handle to gw1Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw1Dur as text
%        str2double(get(hObject,'String')) returns contents of gw1Dur as a double
handles.task.readables.dotsReadableEye(1).windowDur = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw1Dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw1Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw2Size_Callback(hObject, eventdata, handles)
% hObject    handle to gw2Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw2Size as text
%        str2double(get(hObject,'String')) returns contents of gw2Size as a double
handles.task.readables.dotsReadableEye(2).windowSize = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw2Size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw2Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw2Dur_Callback(hObject, eventdata, handles)
% hObject    handle to gw2Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw2Dur as text
%        str2double(get(hObject,'String')) returns contents of gw2Dur as a double
handles.task.readables.dotsReadableEye(2).windowDur = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw2Dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw2Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw3Size_Callback(hObject, eventdata, handles)
% hObject    handle to gw3Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw3Size as text
%        str2double(get(hObject,'String')) returns contents of gw3Size as a double
handles.task.readables.dotsReadableEye(3).windowSize = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw3Size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw3Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw3Dur_Callback(hObject, eventdata, handles)
% hObject    handle to gw3Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw3Dur as text
%        str2double(get(hObject,'String')) returns contents of gw3Dur as a double
handles.task.readables.dotsReadableEye(3).windowDur = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw3Dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw3Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw4Size_Callback(hObject, eventdata, handles)
% hObject    handle to gw4Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw4Size as text
%        str2double(get(hObject,'String')) returns contents of gw4Size as a double
handles.task.readables.dotsReadableEye(4).windowSize = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw4Size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw4Size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function gw4Dur_Callback(hObject, eventdata, handles)
% hObject    handle to gw4Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gw4Dur as text
%        str2double(get(hObject,'String')) returns contents of gw4Dur as a double
handles.task.readables.dotsReadableEye(4).windowDur = ...
   str2double(get(hObject, 'String'));

% --- Executes during object creation, after setting all properties.
function gw4Dur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gw4Dur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in gw1button.
function gw1button_Callback(hObject, eventdata, handles)
% hObject    handle to gw1button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gw1button

% --- Executes on button press in gw2button.
function gw2button_Callback(hObject, eventdata, handles)
% hObject    handle to gw2button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gw2button

% --- Executes on button press in gw3button.
function gw3button_Callback(hObject, eventdata, handles)
% hObject    handle to gw3button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gw3button

% --- Executes on button press in gw4button.
function gw4button_Callback(hObject, eventdata, handles)
% hObject    handle to gw4button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gw4button
