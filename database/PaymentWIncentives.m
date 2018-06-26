function varargout = PaymentWIncentives(varargin)
% PAYMENTWINCENTIVES MATLAB code for PaymentWIncentives.fig
%      PAYMENTWINCENTIVES, by itself, creates a new PAYMENTWINCENTIVES or raises the existing
%      singleton*.
%
%      H = PAYMENTWINCENTIVES returns the handle to a new PAYMENTWINCENTIVES or the handle to
%      the existing singleton*.
%
%      PAYMENTWINCENTIVES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PAYMENTWINCENTIVES.M with the given input arguments.
%
%      PAYMENTWINCENTIVES('Property','Value',...) creates a new PAYMENTWINCENTIVES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PaymentWIncentives_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PaymentWIncentives_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PaymentWIncentives

% Last Modified by GUIDE v2.5 22-Sep-2017 10:42:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PaymentWIncentives_OpeningFcn, ...
                   'gui_OutputFcn',  @PaymentWIncentives_OutputFcn, ...
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


% --- Executes just before PaymentWIncentives is made visible.
function PaymentWIncentives_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PaymentWIncentives (see VARARGIN)

% Choose default command line output for PaymentWIncentives
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PaymentWIncentives wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PaymentWIncentives_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function TotalPaymentWithIncentives_Callback(hObject, eventdata, handles)
% hObject    handle to TotalPaymentWithIncentives (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TotalPaymentWithIncentives as text
%        str2double(get(hObject,'String')) returns contents of TotalPaymentWithIncentives as a double
handles.TotalPaymentWithIncentives = get(hObject,'String');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function TotalPaymentWithIncentives_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TotalPaymentWithIncentives (see GCBO)
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
TP = {handles.TotalPaymentWithIncentives};
blah = readtable('ExperimentArchive.txt');
blah{end,28} = TP
writetable(blah,'ExperimentArchive.txt')