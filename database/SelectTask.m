function varargout = SelectTask(varargin)
% SELECTTASK MATLAB code for SelectTask.fig
%      SELECTTASK, by itself, creates a new SELECTTASK or raises the existing
%      singleton*.
%
%      H = SELECTTASK returns the handle to a new SELECTTASK or the handle to
%      the existing singleton*.
%
%      SELECTTASK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECTTASK.M with the given input arguments.
%
%      SELECTTASK('Property','Value',...) creates a new SELECTTASK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SelectTask_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SelectTask_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SelectTask

% Last Modified by GUIDE v2.5 14-Jun-2018 15:56:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @SelectTask_OpeningFcn, ...
   'gui_OutputFcn',  @SelectTask_OutputFcn, ...
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


% --- Executes just before SelectTask is made visible.
function SelectTask_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SelectTask (see VARARGIN)

% Choose default command line output for SelectTask
handles.output = hObject;
axes(handles.axes1)
matlabImage = imread('neurons.jpeg');
imagesc(matlabImage)
axis off
axis image

% save the dirname argument
handles.defaultDirectory = varargin{1}{:};

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SelectTask wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SelectTask_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in FallingBallsTask.
function FallingBallsTask_Callback(hObject, eventdata, handles)
% hObject    handle to FallingBallsTask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TaskData = readtable('FallingBallsTask.txt');
set(handles.ProtocolNumber,'String',TaskData{1,1});
set(handles.TaskName,'String',TaskData{1,2});
set(handles.TaskDescription,'String',TaskData{1,3});
set(handles.TaskID,'String',TaskData{1,4});
set(handles.DataPathway,'String',TaskData{1,5});
handles.CurrentTask = TaskData;
guidata(hObject,handles)

function ProtocolNumber_Callback(hObject, eventdata, handles)
% hObject    handle to ProtocolNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ProtocolNumber as text
%        str2double(get(hObject,'String')) returns contents of ProtocolNumber as a double


% --- Executes during object creation, after setting all properties.
function ProtocolNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ProtocolNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function TaskName_Callback(hObject, eventdata, handles)
% hObject    handle to TaskName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TaskName as text
%        str2double(get(hObject,'String')) returns contents of TaskName as a double


% --- Executes during object creation, after setting all properties.
function TaskName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TaskName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


function TaskDescription_Callback(hObject, eventdata, handles)
% hObject    handle to TaskDescription (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TaskDescription as text
%        str2double(get(hObject,'String')) returns contents of TaskDescription as a double


% --- Executes during object creation, after setting all properties.
function TaskDescription_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TaskDescription (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


function TaskID_Callback(hObject, eventdata, handles)
% hObject    handle to TaskID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TaskID as text
%        str2double(get(hObject,'String')) returns contents of TaskID as a double


% --- Executes during object creation, after setting all properties.
function TaskID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TaskID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AuditoryTask.
function AuditoryTask_Callback(hObject, eventdata, handles)
% hObject    handle to AuditoryTask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TaskData = readtable(fullfile(handles.defaultDirectory, 'EyetrackerExp.txt'));
set(handles.ProtocolNumber,'String',TaskData{1,1});
set(handles.TaskName,'String',TaskData{1,2});
set(handles.TaskDescription,'String',TaskData{1,3});
set(handles.TaskID,'String',TaskData{1,4});
set(handles.DataPathway,'String',TaskData{1,5});
handles.CurrentTask = TaskData;
guidata(hObject,handles);


% --- Executes on button press in Complete.
function Complete_Callback(hObject, eventdata, handles)
% hObject    handle to Complete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
writetable(handles.CurrentTask,fullfile(handles.defaultDirectory, 'CurrentTask.txt'));
close(SelectTask);

% Open the next diaglog -- pass as cell
SessionData({handles.defaultDirectory});


function DataPathway_Callback(hObject, eventdata, handles)
% hObject    handle to DataPathway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DataPathway as text
%        str2double(get(hObject,'String')) returns contents of DataPathway as a double


% --- Executes during object creation, after setting all properties.
function DataPathway_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DataPathway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AuditoryDecision.
function AuditoryDecision_Callback(hObject, eventdata, handles)
% hObject    handle to AuditoryDecision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TaskData = readtable(fullfile(handles.defaultDirectory, 'AuditoryDecision.txt'));
set(handles.ProtocolNumber,'String',TaskData{1,1});
set(handles.TaskName,'String',TaskData{1,2});
set(handles.TaskDescription,'String',TaskData{1,3});
set(handles.TaskID,'String',TaskData{1,4});
set(handles.DataPathway,'String',TaskData{1,5});
handles.CurrentTask = TaskData;
guidata(hObject,handles);


% --- Executes on button press in TonicOddball.
function TonicOddball_Callback(hObject, eventdata, handles)
% hObject    handle to TonicOddball (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TaskData = readtable(fullfile(handles.defaultDirectory, 'TonicOddball.txt'));
set(handles.ProtocolNumber,'String',TaskData{1,1});
set(handles.TaskName,'String',TaskData{1,2});
set(handles.TaskDescription,'String',TaskData{1,3});
set(handles.TaskID,'String',TaskData{1,4});
set(handles.DataPathway,'String',TaskData{1,5});
handles.CurrentTask = TaskData;
guidata(hObject,handles);
