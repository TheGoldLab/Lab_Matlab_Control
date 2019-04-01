function varargout = SubjectData(varargin)
% SUBJECTDATA MATLAB code for SubjectData.fig
%      SUBJECTDATA, by itself, creates a new SUBJECTDATA or raises the existing
%      singleton*.
%
%      H = SUBJECTDATA returns the handle to a new SUBJECTDATA or the handle to
%      the existing singleton*.
%
%      SUBJECTDATA('CALLBACK',hObject,eventData,handles,...) calls t   he local
%      function named CALLBACK in SUBJECTDATA.M with the given input arguments.
%
%      SUBJECTDATA('Property','Value',...) creates a new SUBJECTDATA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SubjectData_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SubjectData_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SubjectData

% Last Modified by GUIDE v2.5 26-Jun-2018 12:32:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @SubjectData_OpeningFcn, ...
   'gui_OutputFcn',  @SubjectData_OutputFcn, ...
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


% --- Executes just before SubjectData is made visible.
function SubjectData_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SubjectData (see VARARGIN)

% Choose default command line output for SubjectData
handles.output = hObject;

% Add the image
axes(handles.axes1)
matlabImage = imread('neurons.jpeg');
imagesc(matlabImage)
axis off
axis image
handles.Present = 0;

% Save default directory
fullfile(dotsTheMachineConfiguration.getDefaultValue('dataPath'), 'Database');
if ~exist(handles.defaultDirectory, 'dir')
   handles.defaultDirectory = uigetdir([], 'Please select a database directory');
end
set(handles.dirString, 'String', sprintf('Directory: %s', handles.defaultDirectory));

% Update handles structure
global counter
counter = 1;
% handles.allow is the handle for making sure the user selected a tax form
% handles.procede is for making sure the user entered something into the
% PhoneNumber field.
handles.allow = 0;
handles.procede = 0;

% Re-save the handles
guidata(hObject, handles);

% UIWAIT makes SubjectData wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SubjectData_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Sub_ID_Callback(hObject, eventdata, handles)
% hObject    handle to Sub_ID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Sub_ID as text
%        str2double(get(hObject,'String')) returns contents of Sub_ID as a double
SearchData = readtable(fullfile(handles.defaultDirectory, 'SubjectData.txt'));
handles.Sub_ID = get(hObject,'String');
guidata(hObject,handles);
if any(strcmp(SearchData.(1),handles.Sub_ID))
   IDX = strcmp(SearchData.(1),handles.Sub_ID);
   EDX = find(IDX);
   set(handles.FirstName,'String',SearchData{EDX,2});
   handles.FirstName = get(handles.FirstName,'String');
   set(handles.LastName,'String',SearchData{EDX,3});
   handles.LastName = get(handles.LastName,'String');
   set(handles.ContactInfo,'String',SearchData{EDX,4});
   handles.ContactInfo = get(handles.ContactInfo,'String');
   set(handles.PhoneNumber,'String',SearchData{EDX,5});
   handles.PhoneNumber = get(handles.PhoneNumber,'String');
   set(handles.Ethnicity,'String',SearchData{EDX,6});
   handles.Ethnicity = get(handles.Ethnicity,'String');
   set(handles.Gender,'String',SearchData{EDX,7});
   handles.Gender = get(handles.Gender,'String');
   set(handles.DateOfBirth,'String',SearchData{EDX,8});
   handles.DateOfBirth = get(handles.DateOfBirth,'String');
   if SearchData{EDX,9} == 1
      set(handles.radiobutton1,'Value',SearchData{EDX,9});
      handles.TaxForm = get(handles.radiobutton1,'Value');
      handles.allow = 1;
      handles.procede = 1;
   else
      set(handles.radiobutton2,'Value',1);
      handles.TaxForm = 2;
      handles.allow = 1;
      handles.procede = 1;
   end
   handles.Present = 1;
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function Sub_ID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Sub_ID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function FirstName_Callback(hObject, eventdata, handles)
% hObject    handle to FirstName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FirstName as text
%        str2double(get(hObject,'String')) returns contents of FirstName as a double
handles.FirstName = get(hObject,'String');
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function FirstName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FirstName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end



function LastName_Callback(hObject, eventdata, handles)
% hObject    handle to LastName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of LastName as text
%        str2double(get(hObject,'String')) returns contents of LastName as a double
handles.LastName = get(hObject,'String');
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function LastName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LastName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


function ContactInfo_Callback(hObject, eventdata, handles)
% hObject    handle to ContactInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ContactInfo as text
%        str2double(get(hObject,'String')) returns contents of ContactInfo as a double
handles.ContactInfo = get(hObject,'String');
handles.ContactInfo = lower(handles.ContactInfo);
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function ContactInfo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ContactInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end

function Ethnicity_Callback(hObject, eventdata, handles)
% hObject    handle to Ethnicity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Ethnicity as text
%        str2double(get(hObject,'String')) returns contents of Ethnicity as a double
handles.Ethnicity = get(hObject,'String');
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function Ethnicity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ethnicity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Gender.
function Gender_Callback(hObject, eventdata, handles)
% hObject    handle to Gender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Gender contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Gender
handles.Gender = get(hObject,'Value');
if handles.Gender == 2
   handles.Gender = 'Male';
elseif handles.Gender == 3
   handles.Gender = 'Female';
elseif handles.Gender == 4
   handles.Gender = 'Transgender';
elseif handles.Gender == 5
   handles.Gender = 'Do Not Wish To Say';
end
guidata(hObject,handles);
% --- Executes during object creation, after setting all properties.
function Gender_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Gender (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Complete.
function Complete_Callback(hObject, eventdata, handles)
% hObject    handle to Complete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.allow && handles.procede == 1
   
   SubjectID = {handles.Sub_ID};
   FirstName = {handles.FirstName};
   LastName = {handles.LastName};
   Contact = {handles.ContactInfo};
   Ethnicity = {handles.Ethnicity};
   Gender = {handles.Gender};
   DateOfBirth = {handles.DateOfBirth};
   TaxForm = {handles.TaxForm};
   PhoneNumber = {handles.PhoneNumber};
   
   
   CurrentSubject = table(SubjectID,FirstName,LastName,Contact,PhoneNumber,Ethnicity,Gender,DateOfBirth,TaxForm);
   if handles.Present == 0
      writetable(CurrentSubject,fullfile(handles.defaultDirectory, 'CurrentSubject.txt'));
      CurrentSubject = readtable(fullfile(handles.defaultDirectory, 'CurrentSubject.txt'));
      % if exist('SubjectData.txt','file') == 2
      %     writetable(NewData,'NewData.txt');
      OldData = readtable(fullfile(handles.defaultDirectory, 'SubjectData.txt'));
      CombinedData = [OldData;CurrentSubject];
      writetable(CombinedData, fullfile(handles.defaultDirectory, 'SubjectData.txt'));
   else
      writetable(CurrentSubject,fullfile(handles.defaultDirectory, 'CurrentSubject.txt'));
      %     writetable(NewData,'SubjectData.txt');
      % end
      % close(SubjectData)
      % else
      %     close(SubjectData)
   end
   close(SubjectData)
   
   % Call the next gui
   SelectTask({handles.defaultDirectory});
   
elseif handles.allow == 0 && handles.procede == 1
   disp('Please Select a Tax Form')
elseif handles.allow == 1 && handles.procede == 0
   disp('Please Enter a Phone Number. If the participant does not wish to give their phone number, just enter 555-555-5555 into the form.')
end



% --- Executes on button press in DatabaseCheck.
function DatabaseCheck_Callback(hObject, eventdata, handles)
% hObject    handle to DatabaseCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SearchData = readtable(fullfile(handles.defaultDirectory, 'SubjectData.txt'));
if any(strcmp(SearchData.(1),handles.Sub_ID))
   IDX = strcmp(SearchData.(1),handles.Sub_ID);
   EDX = find(IDX);
   set(handles.FirstName,'String',SearchData{EDX,2});
   handles.FirstName = get(handles.FirstName,'String');
   set(handles.LastName,'String',SearchData{EDX,3});
   handles.LastName = get(handles.LastName,'String');
   set(handles.ContactInfo,'String',SearchData{EDX,4});
   handles.ContactInfo = get(handles.ContactInfo,'String');
   set(handles.PhoneNumber,'String',SearchData{EDX,5});
   handles.PhoneNumber = get(handles.PhoneNumber,'String');
   set(handles.Ethnicity,'String',SearchData{EDX,6});
   handles.Ethnicity = get(handles.Ethnicity,'String');
   set(handles.Gender,'String',SearchData{EDX,7});
   handles.Gender = get(handles.Gender,'String');
   set(handles.DateOfBirth,'String',SearchData{EDX,8});
   handles.DateOfBirth = get(handles.DateOfBirth,'String');
   if SearchData{EDX,9} == 1
      set(handles.radiobutton1,'Value',SearchData{EDX,9});
      handles.TaxForm = get(handles.radiobutton1,'Value');
      handles.allow = 1;
      handles.procede = 1;
   else
      set(handles.radiobutton2,'Value',1);
      handles.TaxForm = 2;
      handles.allow = 1;
      handles.procede = 1;
   end
   handles.Present = 1;
end
guidata(hObject,handles);



function DateOfBirth_Callback(hObject, eventdata, handles)
% hObject    handle to DateOfBirth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DateOfBirth as text
%        str2double(get(hObject,'String')) returns contents of DateOfBirth as a double
handles.DateOfBirth = get(hObject,'String');
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function DateOfBirth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DateOfBirth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ClearForm.
function ClearForm_Callback(hObject, eventdata, handles)
% hObject    handle to ClearForm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(SubjectData);
SubjectData;


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2
function uibuttongroup1_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uibuttongroup1
% eventdata  structure with the following fields
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
   case 'radiobutton1'
      handles.TaxForm = 1;
      handles.allow = 1;
   case 'radiobutton2'
      handles.TaxForm = 2;
      handles.allow = 1;
end
guidata(hObject, handles);



function PhoneNumber_Callback(hObject, eventdata, handles)
% hObject    handle to PhoneNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PhoneNumber as text
%        str2double(get(hObject,'String')) returns contents of PhoneNumber as a double
handles.PhoneNumber = get(hObject,'String');
handles.procede = 1;
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function PhoneNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PhoneNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SubIDCheck.
function SubIDCheck_Callback(hObject, eventdata, handles)
% hObject    handle to SubIDCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EmailSubID


% --- Executes on button press in dirButton.
function dirButton_Callback(hObject, eventdata, handles)
% hObject    handle to dirButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Open a dialog to get the new path
handles.defaultDirectory = uigetdir([], 'Please select a database directory');
set(handles.dirString, 'String', sprintf('Directory: %s', handles.defaultDirectory));
guidata(hObject,handles);
