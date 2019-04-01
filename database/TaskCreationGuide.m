function varargout = TaskCreationGuide(varargin)
% TASKCREATIONGUIDE MATLAB code for TaskCreationGuide.fig
%      TASKCREATIONGUIDE, by itself, creates a new TASKCREATIONGUIDE or raises the existing
%      singleton*.
%
%      H = TASKCREATIONGUIDE returns the handle to a new TASKCREATIONGUIDE or the handle to
%      the existing singleton*.
%
%      TASKCREATIONGUIDE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TASKCREATIONGUIDE.M with the given input arguments.
%
%      TASKCREATIONGUIDE('Property','Value',...) creates a new TASKCREATIONGUIDE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TaskCreationGuide_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TaskCreationGuide_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TaskCreationGuide

% Last Modified by GUIDE v2.5 14-Sep-2017 12:43:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TaskCreationGuide_OpeningFcn, ...
                   'gui_OutputFcn',  @TaskCreationGuide_OutputFcn, ...
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


% --- Executes just before TaskCreationGuide is made visible.
function TaskCreationGuide_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TaskCreationGuide (see VARARGIN)

% Choose default command line output for TaskCreationGuide
handles.output = hObject;
axes(handles.axes1)
matlabImage = imread('neurons.jpeg');
imagesc(matlabImage)
axis off
axis image
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TaskCreationGuide wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TaskCreationGuide_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ProtocolNumber_Callback(hObject, eventdata, handles)
% hObject    handle to ProtocolNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ProtocolNumber as text
%        str2double(get(hObject,'String')) returns contents of ProtocolNumber as a double
handles.ProtocolNumber = get(hObject,'String');
guidata(hObject,handles);

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
handles.TaskName = get(hObject,'String');
guidata(hObject,handles);

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
handles.TaskDescription = get(hObject,'String');
guidata(hObject,handles);

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
handles.TaskID = get(hObject,'String');
guidata(hObject,handles);

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


% --- Executes on button press in Complete.
function Complete_Callback(hObject, eventdata, handles)
% hObject    handle to Complete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guidata(hObject,handles)
ProtocolNumber = {handles.ProtocolNumber};
TaskName = {handles.TaskName};
TaskDescription = {handles.TaskDescription};
TaskID = {handles.TaskID};
Pathway = {handles.Pathway};
Payment = {handles.Payment};
LeadExperimenter = {handles.LeadExperimenter};
Apperatus = {handles.Apperatus};
RecordingDevice = {handles.RecordingDevice};
PerSessHour = {handles.PerSessHour};
PerformanceIncentives = {handles.PerformanceIncentives};


TaskText = char(strcat(TaskName,'.txt'));

NewTask = table(ProtocolNumber,TaskName,TaskDescription,TaskID,Pathway,Payment, PerSessHour,PerformanceIncentives, LeadExperimenter, Apperatus,RecordingDevice);
writetable(NewTask,TaskText);
close(TaskCreationGuide)

function Pathway_Callback(hObject, eventdata, handles)
% hObject    handle to Pathway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Pathway as text
%        str2double(get(hObject,'String')) returns contents of Pathway as a double
handles.Pathway = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Pathway_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Pathway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Payment_Callback(hObject, eventdata, handles)
% hObject    handle to Payment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Payment as text
%        str2double(get(hObject,'String')) returns contents of Payment as a double
handles.Payment = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Payment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Payment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function LeadExperimenter_Callback(hObject, eventdata, handles)
% hObject    handle to LeadExperimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LeadExperimenter as text
%        str2double(get(hObject,'String')) returns contents of LeadExperimenter as a double
handles.LeadExperimenter = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function LeadExperimenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LeadExperimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Apperatus_Callback(hObject, eventdata, handles)
% hObject    handle to Apperatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Apperatus as text
%        str2double(get(hObject,'String')) returns contents of Apperatus as a double
handles.Apperatus = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Apperatus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Apperatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in PerSessHour.
function PerSessHour_Callback(hObject, eventdata, handles)
% hObject    handle to PerSessHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PerSessHour contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PerSessHour
handles.PerSessHour = get(hObject,'Value');
if handles.PerSessHour == 2
    handles.PerSessHour = 'Per Session';
elseif handles.PerSessHour == 3
    handles.PerSessHour = 'Hourly Rate';
end
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function PerSessHour_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PerSessHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PerformanceIncentives_Callback(hObject, eventdata, handles)
% hObject    handle to PerformanceIncentives (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PerformanceIncentives as text
%        str2double(get(hObject,'String')) returns contents of PerformanceIncentives as a double
handles.PerformanceIncentives = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function PerformanceIncentives_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PerformanceIncentives (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in RecordingDevice.
function RecordingDevice_Callback(hObject, eventdata, handles)
% hObject    handle to RecordingDevice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns RecordingDevice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RecordingDevice
handles.RecordingDevice = get(hObject,'Value');
if handles.RecordingDevice == 2
    handles.RecordingDevice = 'EyeTracker';
elseif handles.RecordingDevice == 3
    handles.RecordingDevice = 'EEG';
elseif handles.RecordingDevice == 4
    handles.RecordingDevice = 'None';
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function RecordingDevice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RecordingDevice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
