function varargout = EmailSubID(varargin)
% EMAILSUBID MATLAB code for EmailSubID.fig
%      EMAILSUBID, by itself, creates a new EMAILSUBID or raises the existing
%      singleton*.
%
%      H = EMAILSUBID returns the handle to a new EMAILSUBID or the handle to
%      the existing singleton*.
%
%      EMAILSUBID('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EMAILSUBID.M with the given input arguments.
%
%      EMAILSUBID('Property','Value',...) creates a new EMAILSUBID or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EmailSubID_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EmailSubID_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EmailSubID

% Last Modified by GUIDE v2.5 13-Sep-2017 16:25:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EmailSubID_OpeningFcn, ...
                   'gui_OutputFcn',  @EmailSubID_OutputFcn, ...
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


% --- Executes just before EmailSubID is made visible.
function EmailSubID_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EmailSubID (see VARARGIN)

% Choose default command line output for EmailSubID
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EmailSubID wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EmailSubID_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Email_Callback(hObject, eventdata, handles)
% hObject    handle to Email (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Email as text
%        str2double(get(hObject,'String')) returns contents of Email as a double

handles.Email = get(hObject,'String');
handles.Email = lower(handles.Email);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Email_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Email (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SubID_Callback(hObject, eventdata, handles)
% hObject    handle to SubID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SubID as text
%        str2double(get(hObject,'String')) returns contents of SubID as a double


% --- Executes during object creation, after setting all properties.
function SubID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in EmailCheck.
function EmailCheck_Callback(hObject, eventdata, handles)
% hObject    handle to EmailCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SearchData = readtable('/Users/joshuagold/Psychophysics/Projects/Database/SubjectData.txt');
if any(strcmp(SearchData.(4),handles.Email))
    IDX = strcmp(SearchData.(4),handles.Email);
    EDX = find(IDX);
    set(handles.SubID,'String',SearchData{EDX,1});
    handles.SubID = get(handles.SubID,'String');
    disp(handles.SubID)
else
    disp('No Record Found with that Email Address')
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(EmailSubID)
