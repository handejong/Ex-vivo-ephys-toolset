function varargout = measure(varargin)
% MEASURE MATLAB code for measure.fig
%      MEASURE, by itself, creates a new MEASURE or raises the existing
%      singleton*.
%
%      H = MEASURE returns the handle to a new MEASURE or the handle to
%      the existing singleton*.
%
%      MEASURE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MEASURE.M with the given input arguments.
%
%      MEASURE('Property','Value',...) creates a new MEASURE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before measure_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to measure_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help measure

% Last Modified by GUIDE v2.5 17-Dec-2016 13:15:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @measure_OpeningFcn, ...
                   'gui_OutputFcn',  @measure_OutputFcn, ...
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


% --- Executes just before measure is made visible.
function measure_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to measure (see VARARGIN)

% Choose default command line output for measure
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Storing the handle to the sweepset object
handles.paired_sweepset=varargin{1};

% Drawing all elements, but not making them visible
figure(handles.paired_sweepset.handles.figure)
handles.display_handles.peak_up=text(1,1,'empty','visible','off');
handles.display_handles.peak_down=text(1,1,'empty','visible','off');

% Add listener
handles.listener=addlistener(handles.paired_sweepset,'state_change',@(scr, ev) update_everything(scr, ev, handles));

% Update handles structure
guidata(hObject, handles);

% Filling variable in the GUI
set(handles.filename,'String',handles.paired_sweepset.filename)
if strcmp(handles.paired_sweepset.clamp_type,'Voltage (mV)')
    set(handles.text3,'String','Maximum (mV)')
    set(handles.text4,'String','Minimum (mV)')
end

% Find peaks
find_peak(handles);

% Setting a callback for then this GUI is closed and other callbacks
set(hObject,'CloseRequestFcn',{@close_req, handles})


% --- Outputs from this function are returned to the command line.
function varargout = measure_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function measurement_start_Callback(hObject, eventdata, handles)
% hObject    handle to measurement_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of measurement_start as text
%        str2double(get(hObject,'String')) returns contents of measurement_start as a double

find_peak(handles);

% --- Executes during object creation, after setting all properties.
function measurement_start_CreateFcn(hObject, eventdata, handles)
% hObject    handle to measurement_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function measurement_end_Callback(hObject, eventdata, handles)
% hObject    handle to measurement_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of measurement_end as text
%        str2double(get(hObject,'String')) returns contents of measurement_end as a double

find_peak(handles);

% --- Executes during object creation, after setting all properties.
function measurement_end_CreateFcn(hObject, eventdata, handles)
% hObject    handle to measurement_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in display.
function display_Callback(hObject, eventdata, handles)
% hObject    handle to display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'value')==1;
    set(handles.display_handles.peak_up,'visible','on')
    set(handles.display_handles.peak_down,'visible','on')
else
    set(handles.display_handles.peak_up,'visible','off')
    set(handles.display_handles.peak_down,'visible','off')
end

% --- Executes on button press in select_current.
function select_current_Callback(hObject, eventdata, handles)
% hObject    handle to select_current (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of select_current

if get(handles.select_average,'value')==1
    set(handles.select_average,'value',0)
    find_peak(handles);
else
    set(hObject,'value',1)
end

% --- Executes on button press in select_average.
function select_average_Callback(hObject, eventdata, handles)
% hObject    handle to select_average (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of select_average

if get(handles.select_current,'value')==1 
    set(handles.select_current,'value',0)
    find_peak(handles);
else
    set(hObject,'value',1)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Callbacks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% just to make sure that not only this GUI, but also it's associated
% doodles are closed.

function close_req(src,ev,handles)
delete(handles.display_handles.peak_up)
delete(handles.display_handles.peak_down)

 
delete(src)
delete(handles.listener)
 
 
function update_everything(scr,ev,handles)

find_peak(handles);

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Other %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function find_peak(handles)
paired_sweepset=handles.paired_sweepset;

if get(handles.select_average,'value')==1

    average_trace_handle=paired_sweepset.handles.average_trace;
    trace_to_analyse=get(average_trace_handle,'YData');

else
        trace_to_analyse=paired_sweepset.data(:,1,paired_sweepset.current_sweep);
end    
    
SF=paired_sweepset.sampling_frequency;

measurement_start=str2num(get(handles.measurement_start,'String'))*SF;
measurement_end=str2num(get(handles.measurement_end,'String'))*SF;


[peak.up, peak.location_up]=max(trace_to_analyse(measurement_start:measurement_end));
[peak.down, peak.location_down]=min(trace_to_analyse(measurement_start:measurement_end));

peak.location_up=(peak.location_up+measurement_start)/SF;
peak.location_down=(peak.location_down+measurement_start)/SF;

display_text_up= ['\leftarrow     ',num2str(peak.up)];
display_text_down= ['\leftarrow     ',num2str(peak.down)];

set(handles.display_handles.peak_up,'Position',[peak.location_up,peak.up,0],'String',display_text_up);
set(handles.display_handles.peak_down,'Position',[peak.location_down,peak.down,0],'String',display_text_down);

% updating displayed vallues
set(handles.maximum,'String',num2str(peak.up))
set(handles.minimum,'String',num2str(peak.down))
