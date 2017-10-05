function varargout = firing_frequency(varargin)
% FIRING_FREQUENCY MATLAB code for firing_frequency.fig
%      FIRING_FREQUENCY, by itself, creates a new FIRING_FREQUENCY or raises the existing
%      singleton*.
%
%      H = FIRING_FREQUENCY returns the handle to a new FIRING_FREQUENCY or the handle to
%      the existing singleton*.
%
%      FIRING_FREQUENCY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FIRING_FREQUENCY.M with the given input arguments.
%
%      FIRING_FREQUENCY('Property','Value',...) creates a new FIRING_FREQUENCY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before firing_frequency_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to firing_frequency_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help firing_frequency

% Last Modified by GUIDE v2.5 23-Jan-2017 16:40:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @firing_frequency_OpeningFcn, ...
                   'gui_OutputFcn',  @firing_frequency_OutputFcn, ...
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


% --- Executes just before firing_frequency is made visible.
function firing_frequency_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to firing_frequency (see VARARGIN)

% Choose default command line output for firing_frequency
handles.output = hObject;

% UIWAIT makes firing_frequency wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Get the handle of the associated sweepset
handles.paired_sweepset=varargin{1};
figure(handles.paired_sweepset.handles.figure)

% Drawing all things assocaited with firing frequency
x_values=xlim;
y_values=ylim;
handles.display_handles.threshold_line=line([x_values(1) x_values(2)],[-10 -10],'Visible','off','Color',[0 1 0],'LineStyle','--');
handles.display_handles.time_window_lines(1)=line([1149 1149],[y_values(1) y_values(2)],'Visible','off');
handles.display_handles.time_window_lines(2)=line([2149 2149],[y_values(1) y_values(2)],'Visible','off');
handles.display_handles.event_markers=plot([1 2 3 4],[0 0 0 0],'visible','off','LineStyle','none','Marker','x','MarkerSize',15,'Color',[0 0 0]);

% Add listener
handles.listener(1)=addlistener(handles.paired_sweepset,'state_change',@(scr, ev) update_sweep(scr, ev, handles));
handles.listener(2)=addlistener(handles.paired_sweepset,'selection_change',@(scr, ev) update_everything(scr, ev, handles));
handles.listener(3)=addlistener(handles.paired_sweepset,'baseline_change',@(scr, ev) update_everything(scr, ev, handles));

% Update handles structure
guidata(hObject, handles);

% Setting a callback for then this GUI is closed
set(hObject,'CloseRequestFcn',{@close_req, handles})

% Populating some parts of the GUI
set(handles.filename,'String',handles.paired_sweepset.filename)

% Putting the firing_frequency GUI at a location next to the active sweepset on the
% screen.
% Location of the sweepset figure:
hObject.Units='pixels';
Current_position=hObject.Position;
Sweepset_position=handles.paired_sweepset.handles.figure.Position;
hObject.Position=[Sweepset_position(1)+Sweepset_position(3),Sweepset_position(2)+Sweepset_position(4)-Current_position(4),Current_position(3), Current_position(4)];

% Force update
notify(handles.paired_sweepset,'selection_change');


% --- Outputs from this function are returned to the command line.
function varargout = firing_frequency_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function threshold_Callback(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold as text
%        str2double(get(hObject,'String')) returns contents of threshold as a double

threshold_value=str2double(get(hObject,'String'));

set(handles.display_handles.threshold_line,'YData',[threshold_value threshold_value])
notify(handles.paired_sweepset,'baseline_change');


% --- Executes during object creation, after setting all properties.
function threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function start_time_Callback(hObject, eventdata, handles)
% hObject    handle to start_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_time as text
%        str2double(get(hObject,'String')) returns contents of start_time as a double

value=str2double(get(hObject,'String'));
set(handles.display_handles.time_window_lines(1),'XData',[value value])
notify(handles.paired_sweepset,'baseline_change');


% --- Executes during object creation, after setting all properties.
function start_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function end_time_Callback(hObject, eventdata, handles)
% hObject    handle to end_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of end_time as text
%        str2double(get(hObject,'String')) returns contents of end_time as a double
value=str2double(get(hObject,'String'));
set(handles.display_handles.time_window_lines(2),'XData',[value value])
notify(handles.paired_sweepset,'baseline_change');


% --- Executes during object creation, after setting all properties.
function end_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to end_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in display_window.
function display_window_Callback(hObject, eventdata, handles)
% hObject    handle to display_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of display_window



if get(hObject,'value')==1;
    set(handles.display_handles.time_window_lines(1),'Visible','on')
    set(handles.display_handles.time_window_lines(2),'Visible','on')
else
    set(handles.display_handles.time_window_lines(1),'Visible','off')
    set(handles.display_handles.time_window_lines(2),'Visible','off')
end


% --- Executes on button press in disp_threshold.
function disp_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to disp_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of disp_threshold

if get(hObject,'Value')==1
    set(handles.display_handles.threshold_line,'Visible','on')
else
    set(handles.display_handles.threshold_line,'Visible','off')
end


% --- Executes on button press in disp_events.
function disp_events_Callback(hObject, eventdata, handles)
% hObject    handle to disp_events (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of disp_events

if get(hObject,'Value')==1
    set(handles.display_handles.event_markers,'Visible','on')
else
    set(handles.display_handles.event_markers,'Visible','off')
end

% --- Executes on button press in get_events.
function get_events_Callback(hObject, eventdata, handles)
% hObject    handle to get_events (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

events=nan(sum(handles.paired_sweepset.sweep_selection),1000); % max 1000 events per sweep
threshold=get(handles.threshold,'String');
threshold=str2num(threshold);
direction=get(handles.event_direction,'Value');

% figure our if the direction of the events is up or down
if direction==0
    direction='down';
else
    direction='up';
end

max_events=1;
j=0;
for i=1:handles.paired_sweepset.number_of_sweeps
    if handles.paired_sweepset.sweep_selection(i)
        j=j+1;
        [total_events, timestamps]=find_events(handles.paired_sweepset.data(:,1,i), handles.paired_sweepset.X_data, threshold, direction);
        events(j,1:total_events)=timestamps;
        if total_events>max_events
            max_events=total_events;
        end
    end
end

events=events(:,1:max_events);
assignin('base','events',events);
plot=timestamp_plot(events);

% --- Executes on button press in event_direction.
function event_direction_Callback(hObject, eventdata, handles)
% hObject    handle to event_direction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of event_direction
%disp('here');
if get(hObject,'Value')==0
    set(hObject,'String','events go down');
else
    set(hObject,'String','events go up');
end
    
notify(handles.paired_sweepset,'baseline_change');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Callbacks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function close_req(src, callbackdata, handles)
% Delete all doodles from this window

delete(handles.display_handles.threshold_line)
delete(handles.display_handles.time_window_lines)
delete(handles.display_handles.event_markers)
delete(handles.listener(1))
delete(handles.listener(2))
delete(handles.listener(3))
delete(src)
 
 
 
function update_everything(src, callbackdata, handles)


% Update current sweep firing frequency
current_sweep=handles.paired_sweepset.current_sweep;
sweepset=handles.paired_sweepset.data;
selection=handles.paired_sweepset.sweep_selection;
X_trace=handles.paired_sweepset.X_data;
threshold=get(handles.threshold,'String');
threshold=str2num(threshold);
direction=get(handles.event_direction,'Value');

% figure our if the direction of the events is up or down
if direction==0;
    direction='down';
else
    direction='up';
end

[total_events, timestamps]=find_events(sweepset(:,1,current_sweep),X_trace,threshold, direction);

spike_frequency=total_events/((max(X_trace)-min(X_trace))/1000); %Timeline should always be in ms
disp_text=['Selected Sweep: ' num2str(spike_frequency) 'Hz'];
set(handles.selected_sweep,'String',disp_text);

% For this sweep we'll also have the opportunity to indicate events
set(handles.display_handles.event_markers,'XData',timestamps,'YData',ones(1,length(timestamps))*threshold);

% Update all SELECTED sweeps firing frequency
total_events=find_events(sweepset(:,1,selection),X_trace,threshold, direction);
spike_frequency=sum(total_events)/(((max(X_trace)-min(X_trace))/1000)*length(total_events)); %Length total events, is the number of selected sweeps
disp_text=['All Sweeps: ' num2str(spike_frequency) 'Hz'];
set(handles.all_sweeps,'String',disp_text);

% Update current sweep within selected window frequency
start_time=str2double(get(handles.start_time,'String'));
end_time=str2double(get(handles.end_time,'String'));

[total_events, timestamps]=find_events(sweepset(:,1,current_sweep),X_trace,threshold, direction);
spike_frequency=sum(timestamps>start_time & timestamps<end_time)/((end_time-start_time)/1000);
disp_text=['Selected Sweep: ' num2str(spike_frequency) 'Hz'];
set(handles.csws,'String',disp_text);

% Update current sweep OUTSIDE time window
[total_events, timestamps]=find_events(sweepset(:,1,current_sweep),X_trace,threshold, direction);
spike_frequency=sum(timestamps<start_time | timestamps>end_time)/(((max(X_trace)-min(X_trace))-(end_time-start_time))/1000);
disp_text=['Selected Sweep: ' num2str(spike_frequency) 'Hz'];
set(handles.csow,'String',disp_text);

% Update all SELECTED sweeps within selected time window
[total_events, timestamps]=find_events(sweepset(:,1,selection),X_trace,threshold, direction);
spike_frequency=sum(timestamps>start_time & timestamps<end_time)/(((end_time-start_time)/1000)*length(total_events));
disp_text=['All Sweeps: ' num2str(spike_frequency) 'Hz'];
set(handles.asws,'String',disp_text);

% Update all SELECTED sweeps within selected time window
[total_events, timestamps]=find_events(sweepset(:,1,selection),X_trace,threshold, direction);
spike_frequency=sum(timestamps<start_time | timestamps>end_time)/((((max(X_trace)-min(X_trace))-(end_time-start_time))/1000)*length(total_events));
disp_text=['All Sweeps: ' num2str(spike_frequency) 'Hz'];
set(handles.asow,'String',disp_text);

function update_sweep(src, callbackdata, handles)


% Update current sweep firing frequency
current_sweep=handles.paired_sweepset.current_sweep;
sweepset=handles.paired_sweepset.data;
selection=handles.paired_sweepset.sweep_selection;
X_trace=handles.paired_sweepset.X_data;
threshold=get(handles.threshold,'String');
threshold=str2num(threshold);
direction=get(handles.event_direction,'Value');

% figure our if the direction of the events is up or down
if direction==0;
    direction='down';
else
    direction='up';
end

[total_events, timestamps]=find_events(sweepset(:,1,current_sweep),X_trace,threshold, direction);

spike_frequency=total_events/((max(X_trace)-min(X_trace))/1000); %Timeline should always be in ms
disp_text=['Selected Sweep: ' num2str(spike_frequency) 'Hz'];
set(handles.selected_sweep,'String',disp_text);

% For this sweep we'll also have the opportunity to indicate events
set(handles.display_handles.event_markers,'XData',timestamps,'YData',ones(1,length(timestamps))*threshold);

% Update current sweep within selected window frequency
start_time=str2double(get(handles.start_time,'String'));
end_time=str2double(get(handles.end_time,'String'));

[total_events, timestamps]=find_events(sweepset(:,1,current_sweep),X_trace,threshold, direction);
spike_frequency=sum(timestamps>start_time & timestamps<end_time)/((end_time-start_time)/1000);
disp_text=['Selected Sweep: ' num2str(spike_frequency) 'Hz'];
set(handles.csws,'String',disp_text);

% Update current sweep OUTSIDE time window
[total_events, timestamps]=find_events(sweepset(:,1,current_sweep),X_trace,threshold, direction);
spike_frequency=sum(timestamps<start_time | timestamps>end_time)/(((max(X_trace)-min(X_trace))-(end_time-start_time))/1000);
disp_text=['Selected Sweep: ' num2str(spike_frequency) 'Hz'];
set(handles.csow,'String',disp_text);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Other %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [total_events, timestamps]=find_events(Y_trace, X_trace, threshold, direction);
% will output timestamps (in one long array) and total events (per sweep).
% Note that there must be a minimum number of data points between events
% (see below). This is not based on sampling frequency.


timestamps=[];
total_events=zeros(1,length(Y_trace(1,:)));
for i=1:length(Y_trace(1,:));
    
    if strcmp(direction,'up')
        above_threshold=Y_trace(:,i)'>=threshold;
    else
        above_threshold=Y_trace(:,i)'<=threshold; %should be called 'below_threshold' I guess.
    end
    
    transpose(1,:)=[0 above_threshold(1:end-1)];
    for j=1:25 %must be 25 data points between events, can change here
        transpose=[0 transpose(1:end-1)]+transpose;
    end
    timestamps_temp=above_threshold==1 & transpose==0;
      
    timestamps=[timestamps X_trace(timestamps_temp)];
    total_events(i)=sum(timestamps_temp);
  
end

function [ figure_handle ] = timestamp_plot( event_list )
%TIMESTAMP_PLOT will plot events and average firing frequency
%   Currently, this plot does not update after state change in the sweep
%   set.

% Variables
size_input=size(event_list);
max_events=size_input(2);
sweeps=size_input(1);

% Figure
figure_handle=figure();

% Actual plot
Y_values=repmat([1:sweeps]',1,max_events);
subplot(2,1,1)
event_plot=plot(event_list',fliplr(Y_values'),...
    'LineStyle','none',...
    'Marker','x',...
    'MarkerFaceColor',[0 0 1],...
    'MarkerEdgeCOlor',[0 0 1]);
%xlim([0 5000])
xlabel('time (ms)')
ylabel('sweep #')  

% Figure out the distribution
i=1;
event_distribution=zeros(1,51);
binsize=0.2;
for t=0:binsize:10
    event_distribution(1,i)=(sum(sum((event_list/1000)>=t-(binsize/2) & (event_list/1000)<t+(binsize/2))))/(binsize*sweeps); %ms and s
    event_distribution(2,i)=t;
    i=i+1;
end

assignin('base','distribution',event_distribution)

subplot(2,1,2)
plot(event_distribution(2,:),event_distribution(1,:))
xlim([0 5])
xlabel('time (s)')
ylabel('firing frequency (Hz)')  
