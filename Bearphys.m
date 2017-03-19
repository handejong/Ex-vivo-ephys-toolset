function varargout = Bearphys(varargin)
% BEARPHYS MATLAB code for Bearphys.fig
%      BEARPHYS, by itself, creates a new BEARPHYS or raises the existing
%      singleton*.
%
%      H = BEARPHYS returns the handle to a new BEARPHYS or the handle to
%      the existing singleton*.
%
%      BEARPHYS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BEARPHYS.M with the given input arguments.
%
%      BEARPHYS('Property','Value',...) creates a new BEARPHYS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Bearphys_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Bearphys_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Bearphys

% Last Modified by GUIDE v2.5 23-Jan-2017 17:29:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Bearphys_OpeningFcn, ...
                   'gui_OutputFcn',  @Bearphys_OutputFcn, ...
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

% --- Executes just before Bearphys is made visible.
function Bearphys_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Bearphys (see VARARGIN)

% Choose default command line output for Bearphys
handles.output = hObject;

% The data struct contains infor about the currently active sweepsets
data.number_active=0;
data.sweepset_handles=sweepset.empty(0,20);
data.sweepset_SIN=zeros(0,20); %sins are specific identifyers for every sweepset

setappdata(handles.output,'data',data);

% Update handles structure
guidata(hObject, handles);

% Add listener for being closed
set(handles.output,'CloseRequestFcn',{@close_req, handles})

% --- Outputs from this function are returned to the command line.
function varargout = Bearphys_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in open_file.
function open_file_Callback(hObject, eventdata, handles)
% hObject    handle to open_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

new_sweepset=sweepset('user_select','on');
if ~isvalid(new_sweepset) %user pressed cancel
    return
end

% update data struct
data=getappdata(handles.output,'data');
data.number_active=data.number_active+1;
data.sweepset_handles(data.number_active)=new_sweepset;
new_sweepset.settings.SIN=rand(1); %10000 possibilities
data.sweepset_SIN(data.number_active)=new_sweepset.settings.SIN;

setappdata(handles.output,'data',data);
setappdata(handles.output,'paired_sweepset',new_sweepset);

% listeners to see if anything changes in the sweepsets
listeners=getappdata(handles.output,'listeners');
listeners=[listeners addlistener(new_sweepset,'state_change',@(scr, ev) update_everything(scr, ev, handles))];
listeners=[listeners addlistener(new_sweepset,'sweepset_closed',@(scr, ev) sweepset_closed(scr, ev, handles,new_sweepset.settings.SIN))];
setappdata(handles.output,'listeners',listeners);

update_everything(handles.output,'empty',handles);

% Make all the buttons visible
buttons_visible(handles,'on');

% --- Executes on slider movement.
function sweep_selector_Callback(hObject, eventdata, handles)
% hObject    handle to sweep_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
        current_sweepset.move_sweep(round(get(hObject,'Value')));
    end

% --- Executes during object creation, after setting all properties.
function sweep_selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sweep_selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in substract_baseline.
function substract_baseline_Callback(hObject, eventdata, handles)
% hObject    handle to substract_baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of substract_baseline
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
        current_sweepset.substract_baseline
    end

% --- Executes on button press in measure.
function measure_Callback(hObject, eventdata, handles)
% hObject    handle to measure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
        if ishandle(current_sweepset.handles.measurement)
        else
            current_sweepset.handles.measurement=measure(current_sweepset);
            notify(current_sweepset,'state_change')
        end
    end

% --- Executes on button press in firing_frequency.
function firing_frequency_Callback(hObject, eventdata, handles)
% hObject    handle to firing_frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
        if ishandle(current_sweepset.handles.firing_frequency)
        else
            current_sweepset.handles.firing_frequency=firing_frequency(current_sweepset);
            notify(current_sweepset,'selection_change') %force update of firing frequency
        end
    end

% --- Executes on button press in average_trace.
function average_trace_Callback(hObject, eventdata, handles)
% hObject    handle to average_trace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of average_trace

    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
        status=get(current_sweepset.handles.average_trace,'visible');
        if strcmp(status,'off')
            set(current_sweepset.handles.average_trace,'visible','on')
        else
            set(current_sweepset.handles.average_trace,'visible','off')
        end
        notify(current_sweepset,'state_change')
    end

% --- Executes on button press in background.
function background_Callback(hObject, eventdata, handles)
% hObject    handle to background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of background
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
        status=get(current_sweepset.handles.all_sweeps(1),'visible');
        if strcmp(status,'off')
            set(current_sweepset.handles.all_sweeps,'visible','on')
        else
            set(current_sweepset.handles.all_sweeps,'visible','off')
        end
        notify(current_sweepset,'state_change')
    end

function smooth_average_Callback(hObject, eventdata, handles)
% hObject    handle to smooth_average (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smooth_average as text
%        str2double(get(hObject,'String')) returns contents of smooth_average as a double
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
       SF=current_sweepset.sampling_frequency;
       current_sweepset.settings.average_smooth=round(str2num(get(hObject,'String'))*SF);
       set(current_sweepset.handles.average_trace,'YData',current_sweepset.average_trace); %force update
    end

% --- Executes during object creation, after setting all properties.
function smooth_average_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smooth_average (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in baseline_method.
function baseline_method_Callback(hObject, eventdata, handles)
% hObject    handle to baseline_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns baseline_method contents as cell array
%        contents{get(hObject,'Value')} returns selected item from baseline_method
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset');
       switch get(hObject,'Value')
           case 1
               current_sweepset.settings.baseline_info.method='standard';    
           case 2
               current_sweepset.settings.baseline_info.method='whole_trace';
           case 3
               current_sweepset.settings.baseline_info.method='moving_average_1s';
       end
    end

% --- Executes during object creation, after setting all properties.
function baseline_method_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baseline_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in print_selection.
function print_selection_Callback(hObject, eventdata, handles)
% hObject    handle to print_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    current_sweepset=getappdata(handles.output,'paired_sweepset');
    test_type=whos('current_sweepset');
    
    if strcmp(test_type.class,'sweepset')
       current_sweepset.sweep_selection
    end

% --- Executes on button press in smooth_trace.
function smooth_trace_Callback(hObject, eventdata, handles)
% hObject    handle to smooth_trace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of smooth_trace
current_sweepset=getappdata(handles.output,'paired_sweepset');
 
if get(hObject,'Value')==1
    current_sweepset.settings.smoothed=true;
else
    current_sweepset.settings.smoothed=false;
end
    
function smooth_ms_Callback(hObject, eventdata, handles)
% hObject    handle to smooth_ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of smooth_ms as text
%        str2double(get(hObject,'String')) returns contents of smooth_ms as a double

input=str2num(get(hObject,'String'));
current_sweepset=getappdata(handles.output,'paired_sweepset');

current_sweepset.settings.smooth_factor=input;

% --- Executes during object creation, after setting all properties.
function smooth_ms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to smooth_ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% other functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function update_everything(scr,ev,handles)
% Update all aspects of this GUI
    if strcmp(ev,'closed_sweepset')
        %means a sweepset was just closed, find the NEXT one on top
        list=get(0,'children');
        found_it=0;
        i=1;
        while found_it==0;
            i=i+1; %NEXT sweepset
            current_sweepset=getappdata(list(i),'object');
            test_type=whos('current_sweepset');
            if strcmp(test_type.class,'sweepset')
                found_it=1;
                figure(list(i));
            end
        end
    else            
    % figure out which figure is currently active and link this GUI
    current_sweepset=getappdata(gcf,'object');
    test_type=whos('current_sweepset');
    end
    
    if strcmp(test_type.class,'sweepset')
        set(handles.sweepset_name,'String',current_sweepset.filename)
        set(handles.sweep_selector,...
            'Max',current_sweepset.number_of_sweeps,...
            'Value',current_sweepset.current_sweep,...
            'SliderStep', [1/current_sweepset.number_of_sweeps , 10/current_sweepset.number_of_sweeps])
        set(handles.sweep_number,'String',['sweep ' num2str(current_sweepset.current_sweep)])
        if current_sweepset.sweep_selection(current_sweepset.current_sweep)==true
            set(handles.selected,'String','selected','ForegroundColor',[0 0 1])
        else
            set(handles.selected,'String','rejected','ForegroundColor',[1 0 0])
        end
        if strcmp(get(current_sweepset.handles.average_trace,'visible'),'on')
            set(handles.average_trace,'Value',1)
        else
            set(handles.average_trace,'Value',0)
        end
        if current_sweepset.settings.baseline_info.substracted==true
            set(handles.substract_baseline,'Value',1)
        else
            set(handles.substract_baseline,'Value',0)
        end
        if strcmp(get(current_sweepset.handles.all_sweeps(1),'visible'),'on')
            set(handles.background,'Value',1)
        else
            set(handles.background,'Value',0)
        end
        
        % store the figure handle of the selected figure
        setappdata(handles.output,'paired_sweepset',current_sweepset);
    else %the gcf was not a sweepset, but we have to update something...
        update_everything(handles.output,'closed_sweepset',handles);
    end
    
function sweepset_closed(scr, ev, handles, SIN)
    % Will update the selection of availble sweeps
    
        data=getappdata(handles.output,'data');
            data.sweepset_SIN=data.sweepset_SIN(data.sweepset_SIN~=SIN);
            data.number_active=data.number_active-1;
            data.sweepset_handles=data.sweepset_handles(isvalid(data.sweepset_handles));
        setappdata(handles.output,'data',data)
        
        if data.number_active>0
            update_everything(scr, 'closed_sweepset', handles);
        else
            buttons_visible(handles,'off')
        end
        
function buttons_visible(handles,input)
set(handles.substract_baseline,'Visible',input)
set(handles.sweep_selector,'Visible',input)
set(handles.average_trace,'Visible',input)
set(handles.background,'Visible',input)
set(handles.measure,'Visible',input)
set(handles.firing_frequency,'Visible',input)
set(handles.print_selection,'Visible',input)
set(handles.baseline_method,'Visible',input)
set(handles.smooth_average,'Visible',input)
set(handles.smooth_average_text,'Visible',input)
set(handles.text5,'Visible',input)
set(handles.sweep_number,'Visible',input)
set(handles.selected,'Visible',input)
set(handles.sweepset_name,'Visible',input)
set(handles.smooth_trace,'Visible',input)
set(handles.smooth_ms,'Visible',input)
set(handles.text6,'Visible',input)

function close_req(scr, ev, handles)
% runs when Bearphys is asked to close, but leaves sweepsets open, therfore
% listeners have to be delted.

listeners=getappdata(handles.output,'listeners');

for i=1:length(listeners)
    delete(listeners(1,i))
end

delete(scr)
disp('bye')



