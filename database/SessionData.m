function varargout = SessionData(varargin)
% SESSIONDATA MATLAB code for SessionData.fig
%      SESSIONDATA, by itself, creates a new SESSIONDATA or raises the existing
%      singleton*.
%
%      H = SESSIONDATA returns the handle to a new SESSIONDATA or the handle to
%      the existing singleton*.
%
%      SESSIONDATA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SESSIONDATA.M with the given input arguments.
%
%      SESSIONDATA('Property','Value',...) creates a new SESSIONDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SessionData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SessionData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SessionData

% Last Modified by GUIDE v2.5 24-Aug-2017 16:49:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @SessionData_OpeningFcn, ...
   'gui_OutputFcn',  @SessionData_OutputFcn, ...
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


% --- Executes just before SessionData is made visible.
function SessionData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SessionData (see VARARGIN)

% Choose default command line output for SessionData
handles.output = hObject;

% Add the image
axes(handles.axes1)
matlabImage = imread('neurons.jpeg');
imagesc(matlabImage)
axis off
axis image

% save the dirname argument
handles.defaultDirectory = varargin{1}{:};

% re-save the handles
guidata(hObject, handles);

% UIWAIT makes SessionData wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SessionData_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function SessionTime_Callback(hObject, eventdata, handles)
% hObject    handle to SessionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SessionTime as text
%        str2double(get(hObject,'String')) returns contents of SessionTime as a double

handles.SessionTime = get(hObject,'String');
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function SessionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SessionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
% annoying = clock;
% moreannoying = num2str(annoying);
% reallyannoying = moreannoying([48:49 63:65]);
% set(hObject,'String',reallyannoying);
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function SessionDate_Callback(hObject, eventdata, handles)
% hObject    handle to SessionDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SessionDate as text
%        str2double(get(hObject,'String')) returns contents of SessionDate as a double
handles.SessionDate = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function SessionDate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SessionDate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function SubjectID_Callback(hObject, eventdata, handles)
% hObject    handle to SubjectID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SubjectID as text
%        str2double(get(hObject,'String')) returns contents of SubjectID as a double
handles.SubjectID = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function SubjectID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubjectID (see GCBO)
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



function TaskVersion_Callback(hObject, eventdata, handles)
% hObject    handle to TaskVersion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TaskVersion as text
%        str2double(get(hObject,'String')) returns contents of TaskVersion as a double
handles.TaskVersion = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function TaskVersion_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TaskVersion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function Experimenter_Callback(hObject, eventdata, handles)
% hObject    handle to Experimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Experimenter as text
%        str2double(get(hObject,'String')) returns contents of Experimenter as a double

handles.Experimenter = get(hObject,'String');
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function Experimenter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Experimenter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function SessionsNumber_Callback(hObject, eventdata, handles)
% hObject    handle to SessionsNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SessionsNumber as text
%        str2double(get(hObject,'String')) returns contents of SessionsNumber as a double

handles.SessionsNumber = get(hObject,'String');
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function SessionsNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SessionsNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Consent.
function Consent_Callback(hObject, eventdata, handles)
% hObject    handle to Consent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Consent
handles.Consent = get(hObject,'Value');
guidata(hObject,handles);


function Protocol_Callback(hObject, eventdata, handles)
% hObject    handle to Protocol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Protocol as text
%        str2double(get(hObject,'String')) returns contents of Protocol as a double
handles.Protocol = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Protocol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Protocol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AutoComplete.
function AutoComplete_Callback(hObject, eventdata, handles)
% hObject    handle to AutoComplete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

TaskData = readtable(fullfile(handles.defaultDirectory, 'CurrentTask.txt'));
set(handles.Protocol,'String',TaskData{1,1});
handles.Protocol = get(handles.Protocol,'String');

set(handles.TaskID,'String',TaskData{1,4});
handles.TaskID = get(handles.TaskID,'String');

First = clock;
Second = First(4:5);
Third = sprintf('%g:%g',Second(1),Second(2));

set(handles.SessionDate,'String',date);
handles.SessionDate = get(handles.SessionDate,'String');

set(handles.SessionTime,'String',Third);
handles.SessionTime = get(handles.SessionTime,'String');

set(handles.Payment,'String',TaskData{1,6})
handles.Payment = get(handles.Payment,'String');

set(handles.PerSessHour,'String',TaskData{1,7})
handles.PerSessHour = get(handles.PerSessHour,'String');

CurrentSubject = readtable(fullfile(handles.defaultDirectory, 'CurrentSubject.txt'));
set(handles.SubjectID,'String',CurrentSubject{1,1})
handles.SubjectID = get(handles.SubjectID,'String');
guidata(hObject,handles);

% --- Executes on button press in Complete.
function Complete_Callback(hObject, eventdata, handles)
% hObject    handle to Complete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
guidata(hObject,handles)
if handles.Consent == 1
   SessionTime = {handles.SessionTime};
   SessionDate = {handles.SessionDate};
   TaskVersion = {handles.TaskVersion};
   Experimenter = {handles.Experimenter};
   SessionsNumber = {handles.SessionsNumber};
   Consent = {handles.Consent};
   ExperimenterNotes = {handles.ExperimenterNotes};
   
   CurrentSubject = readtable(fullfile(handles.defaultDirectory, 'CurrentSubject.txt'));
   CurrentTask = readtable(fullfile(handles.defaultDirectory, 'CurrentTask.txt'));
   TotalPayment = CurrentTask{1,6};
   CurrentSession = table(SessionTime,SessionDate,TaskVersion,Experimenter,SessionsNumber,Consent,ExperimenterNotes, TotalPayment);
   
   ExperimentLog = [CurrentSubject CurrentTask CurrentSession];
   writetable(ExperimentLog,fullfile(handles.defaultDirectory, 'ExperimentLog.txt'));
   ExperimentLog = readtable(fullfile(handles.defaultDirectory, 'ExperimentLog.txt'));
   
   if exist(fullfile(handles.defaultDirectory, 'ExperimentArchive.txt'), 'file');
      
      ExperimentArchive = readtable(fullfile(handles.defaultDirectory, 'ExperimentArchive.txt'));
      ExperimentAddition = [ExperimentArchive;ExperimentLog];
      writetable(ExperimentAddition,fullfile(handles.defaultDirectory, 'ExperimentArchive.txt'));
   else
      writetable(ExperimentLog,fullfile(handles.defaultDirectory, 'ExperimentArchive.txt'));
   end
   close(SessionData);
else
   disp('You can not proceed without informed consent.')
end


function ExperimenterNotes_Callback(hObject, eventdata, handles)
% hObject    handle to ExperimenterNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ExperimenterNotes as text
%        str2double(get(hObject,'String')) returns contents of ExperimenterNotes as a double
handles.ExperimenterNotes = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function ExperimenterNotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExperimenterNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function PerSessHour_Callback(hObject, eventdata, handles)
% hObject    handle to PerSessHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PerSessHour as text
%        str2double(get(hObject,'String')) returns contents of PerSessHour as a double


% --- Executes during object creation, after setting all properties.
function PerSessHour_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PerSessHour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end
