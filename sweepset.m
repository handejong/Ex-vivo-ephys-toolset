classdef sweepset < handle
    %SWEEPSET creates an object containing a set of sweeps
    %   This class uses abfload (by Harald Hentschke) to load a set of
    %   axonclamp sweeps into an object. The object creates a figure and is
    %   accesible either by keyboard (see keypress callback) or by a
    %   customized GUI.
    %
    %   Current methods include 'average trace' and 'substract baseline'.
    %   New methods are easily added. If an opperation on the data requires
    %   that the figure is updated, call 'update_figure('event_type').
    %   Update figure can be customized to only update specific parts of
    %   the figure.
    %
    %   For GUI design: note that the object handle is stored in the
    %   appdata of the figure. Thus getappdata(gcf,'object') provides the
    %   handle of the object that controls the figure.
    %
    %   INPUTS:
    %       - 'user_select', ('on'/'off')           | UI for file selection
    %       - 'filename', 'path/filename'           | open selected file
    %       - 'directory', ('on'/'off'/filepath)    | will open all files
    %                                                 in pwd or filepath. 
    %
    %   Made by Johannes de Jong, j.w.dejong@berkeley.edu
    
    
    properties (SetObservable)
        filename            % .abf file
        file_header         % provided by abfload
        data                % sweepset as it is currently used
        original_data       % sweepset as is was imported at startup
        X_data              % X_axis
        clamp_type          % Voltage or current clamp
        sampling_frequency  % in KHz           
        number_of_sweeps    % number of sweeps in the set
        handles             % Of all aspects of the figure
        sweep_selection     % sweeps can be either rejected or selected by the user
        current_sweep       % the currently active sweep
        current_sweep_R     % the current sweep selected with right mouse button
        outside_world       % used when this objects thinks the outside world might want to update something.
        settings            % struct with settings, used for interaction with user and GUI
        click_info          % information about mouse clicks
    end
    
    properties (Dependent, SetObservable)
        baseline            % can be value or complex, depending on the baseline substraction method       
        average_trace       % average trace is computed using only the selected sweeps
        base_data           % used for dynamic updating of the figure after settings change
    end
    
    methods
        
        function this_sweepset = sweepset(varargin)
            
            % Deal with arguments
            
            for i=1:2:nargin
            Unable_to_read_input=true; %untill proven otherwise    
                % open input filename
                if strcmp(varargin{i},'filename')
                    this_sweepset.filename=varargin{i+1};
                    [this_sweepset.data, sampling_interval, this_sweepset.file_header]=abfload(this_sweepset.filename);
                    this_sweepset.sampling_frequency=10^3/sampling_interval; % The sampling frequency in kHz 
                    Unable_to_read_input=false;
                end
                
                % allow the user to select file (trumps input filename)
                if strcmp(varargin{i},'user_select') && strcmp(varargin{i+1},'on')
                    [temp_filename, path] = uigetfile({'*.abf'},'select files','MultiSelect','off');
                    if temp_filename==0
                        delete(this_sweepset)
                        disp('no file selected')
                        return
                    end
                    filename_path=fullfile(path, temp_filename);
                    [this_sweepset.data, sampling_interval, this_sweepset.file_header]=abfload(filename_path);
                    this_sweepset.sampling_frequency=10^3/sampling_interval; % The sampling frequency in kHz
                    this_sweepset.filename=temp_filename;
                    Unable_to_read_input=false;
                end
                
                % Open all .abf files in this directory.
                if strcmp(varargin{i},'directory')
                    
                    % First figure out the directory that should be openend
                    if strcmp(varargin{i+1},'on')
                        filelist=[pwd '/*' '.abf'];
                        filelist=dir(filelist);
                    elseif length(varargin{i+1})>3
                        % probably a path, check if folder exist
                        if exist(varargin{i+1},'dir')
                            filelist=[pwd '/*' '.abf'];
                            filelist=dir(filelist);
                            disp(['Loading folder: ', varargin{i+1}]);
                        else
                            error('Unable to locate this folder')
                        end
                    elseif strcmp(varargin{i+1},'off')
                        disp('no folder loaded')
                        return
                    else
                        error('Failed directory command.')
                    end
                    
                    if isempty(filelist)
                        disp('no .abf files in this folder')
                    end
                    
                    % Open all the .abf files as sweepset objects
                    for j=1:length(filelist)
                        object=sweepset('filename',filelist(j).name);
                        name=['S_' object.filename(object.filename~=' ' & object.filename~='.' & object.filename~='+' & object.filename~='-')];
                        assignin('base',name,object); % Printing them all to the workspace
                    end
                    
                    % Get the name of this folder
                    [~, folder_name, ~]=fileparts(pwd);
                    folder_name=folder_name(folder_name~=' ' & folder_name~='+' & folder_name~='-' & folder_name~='.');
                    
                    combiner=trace_combiner;
                    
                    % Storing the handle to the combiner in the workspace
                    assignin('base',folder_name,combiner)
                    
                    delete(this_sweepset);
                    Unable_to_read_input=false;
                    return 
                end
                
                if Unable_to_read_input
                    error(['Unable to understand input: ', varargin{i}]);
                end
            end
            
            % Current or voltage clamp
            if strcmp(this_sweepset.file_header.recChUnits{1},'pA')
                this_sweepset.clamp_type='Current (pA)';
            else
                this_sweepset.clamp_type='Voltage (mV)';
            end
            
            % Setting other variables
            this_sweepset.X_data=[0:1/this_sweepset.sampling_frequency:(length(this_sweepset.data)/this_sweepset.sampling_frequency)-(1/this_sweepset.sampling_frequency)];
            this_sweepset.current_sweep=1;
            this_sweepset.number_of_sweeps=length(this_sweepset.data(1,1,:));
            this_sweepset.sweep_selection=true(1,this_sweepset.number_of_sweeps);
            this_sweepset.settings.baseline_info.start=1;
            this_sweepset.settings.baseline_info.end=100;
            this_sweepset.settings.baseline_info.method='standard';
            this_sweepset.settings.baseline_info.substracted=false;
            this_sweepset.settings.average_smooth=0;
            this_sweepset.settings.smoothed=false;
            this_sweepset.settings.smooth_factor=0;
            
            % Make a figure
            this_sweepset.handles.figure=figure('position',[-1840,-137,700,500]);
            set(this_sweepset.handles.figure,'name',char(this_sweepset.filename),'numbertitle','off');
            hold on
            
            % Add callbacks to the figure
            set(this_sweepset.handles.figure,'keypressfcn',@this_sweepset.key_press);
                
            % Figure axis
            xlabel('time (ms)')
            ylabel(this_sweepset.clamp_type)              
            floor=min(min(this_sweepset.data))-10;
            roof=max(max(this_sweepset.data))+10;
            disp_right=round(length(this_sweepset.data(:,1,1))/this_sweepset.sampling_frequency);
            axis([0 disp_right floor roof])
            haxes=findobj(this_sweepset.handles.figure,'type','axes'); %axes handle
            
            % This is the context menu (drop down) for the sweeps
            this_sweepset.handles.drop_down.sweep_menu=uicontextmenu;
            this_sweepset.handles.drop_down.m1=uimenu(this_sweepset.handles.drop_down.sweep_menu,'Label','include sweep','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.drop_down.m2=uimenu(this_sweepset.handles.drop_down.sweep_menu,'Label','reject sweep','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.drop_down.m3=uimenu(this_sweepset.handles.drop_down.sweep_menu,'Label','smooth 1ms','Callback',@this_sweepset.sweep_context);
            
            % This is the context menu (drop down) for the average trace
            this_sweepset.handles.average_drop_down.menu=uicontextmenu;
            this_sweepset.handles.average_drop_down.m1=uimenu(this_sweepset.handles.average_drop_down.menu,'Label','measure peak','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.average_drop_down.m2=uimenu(this_sweepset.handles.average_drop_down.menu,'Label','smooth 1ms','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.average_drop_down.m3=uimenu(this_sweepset.handles.average_drop_down.menu,'Label','export average','Callback',@this_sweepset.sweep_context);
            
            % This is the context menu (drop down) for the current trace
            % This menu is not in use right now, the current trace uses the
            % same drop down as all other sweeps.
            this_sweepset.handles.current_drop_down.menu=uicontextmenu;
            this_sweepset.handles.current_drop_down.m1=uimenu(this_sweepset.handles.current_drop_down.menu,'Label','include sweep','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.current_drop_down.m2=uimenu(this_sweepset.handles.current_drop_down.menu,'Label','reject sweep','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.current_drop_down.m3=uimenu(this_sweepset.handles.current_drop_down.menu,'Label','export average','Callback',@this_sweepset.sweep_context);
            
            % This is the context menu (drop down) for the plot as a whole
            this_sweepset.handles.background_drop_down.menu=uicontextmenu;
            haxes.UIContextMenu=this_sweepset.handles.background_drop_down.menu;
            this_sweepset.handles.background_drop_down.m1=uimenu(this_sweepset.handles.background_drop_down.menu,'Label','substract baseline','Callback',@this_sweepset.substract_baseline);
            this_sweepset.handles.background_drop_down.background_menu=uimenu('Parent',this_sweepset.handles.background_drop_down.menu,'Label','baseline method');
            this_sweepset.handles.background_drop_down.n1=uimenu('Parent', this_sweepset.handles.background_drop_down.background_menu,'Label','standard','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.background_drop_down.n2=uimenu('Parent', this_sweepset.handles.background_drop_down.background_menu,'Label','whole trace','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.background_drop_down.n3=uimenu('Parent', this_sweepset.handles.background_drop_down.background_menu,'Label','moving average 1s','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.background_drop_down.m2=uimenu(this_sweepset.handles.background_drop_down.menu,'Label','display average','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.background_drop_down.m3=uimenu(this_sweepset.handles.background_drop_down.menu,'Label','display all sweeps','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.background_drop_down.m4=uimenu(this_sweepset.handles.background_drop_down.menu,'Label','refocus','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.background_drop_down.m5=uimenu(this_sweepset.handles.background_drop_down.menu,'Label','combine sweepsets','Callback',@this_sweepset.sweep_context);
            this_sweepset.handles.backgorund_drop_down.m6=uimenu(this_sweepset.handles.background_drop_down.menu,'Label','export data','Callback',@this_sweepset.sweep_context);
 
            % Plot all the sweeps          
            this_sweepset.handles.all_sweeps=plot(this_sweepset.X_data,squeeze(this_sweepset.data(:,1,:)),'b','visible','on');
                for i=1:length(this_sweepset.handles.all_sweeps)
                    % Adding Button press callbacks to all sweeps
                    sweepname=['sweep ',num2str(i)];
                    set(this_sweepset.handles.all_sweeps(i),'UserData',i,'DisplayName',sweepname);
                    set(this_sweepset.handles.all_sweeps(i),'ButtonDownFcN',@this_sweepset.click_on_sweep)
                    % Adding the drop down menu to all sweeps
                    this_sweepset.handles.all_sweeps(i).UIContextMenu = this_sweepset.handles.drop_down.sweep_menu;
                end
                
            % Plot the current sweep (in red)
            this_sweepset.handles.current_sweep=plot(this_sweepset.X_data,this_sweepset.data(:,1,this_sweepset.current_sweep),'r');
            set(this_sweepset.handles.current_sweep,'UserData','current_sweep','DisplayName','sweep 1');
            set(this_sweepset.handles.current_sweep,'ButtonDownFcN',@this_sweepset.click_on_sweep)
            this_sweepset.handles.current_sweep.UIContextMenu = this_sweepset.handles.drop_down.sweep_menu;
            
            % Plot the average trace (in green)
            this_sweepset.handles.average_trace=plot(this_sweepset.X_data,this_sweepset.average_trace,'g','visible','off');
            set(this_sweepset.handles.average_trace,'UserData','average_trace','DisplayName','average');
            set(this_sweepset.handles.average_trace,'ButtonDownFcN',@this_sweepset.click_on_sweep)
            this_sweepset.handles.average_trace.UIContextMenu = this_sweepset.handles.average_drop_down.menu;
            
            % Add listener
            addlistener(this_sweepset,'sweep_selection','PostSet',@this_sweepset.plot_update);
            addlistener(this_sweepset,'settings','PostSet',@this_sweepset.plot_update);
            
            % We will manipulate data, so storing the original data as well
            this_sweepset.original_data=this_sweepset.data;
            
            % Put the handle to this object in the figure (for GUI use)
            setappdata(this_sweepset.handles.figure,'object',this_sweepset)
            
            % Add a callback for a close request
            set(this_sweepset.handles.figure,'CloseRequestFcn', @this_sweepset.close_req)
            
            % Final settings
            this_sweepset.handles.measurement='not a handle'; % no measuremenet open
            this_sweepset.handles.firing_frequency='not a handle'; % no FF measurement open
            
        end
        
        function move_sweep(this_sweepset, new_selected_sweep)
            % will move the selected sweep to new_selected_sweep
            
            if new_selected_sweep>0 && new_selected_sweep<=this_sweepset.number_of_sweeps
                % simply won't do it if that sweep is not available
                this_sweepset.current_sweep=new_selected_sweep;                
                set(this_sweepset.handles.current_sweep,'YData',this_sweepset.data(:,1,this_sweepset.current_sweep),'DisplayName',['sweep ',num2str(this_sweepset.current_sweep)]);
                notify(this_sweepset,'state_change')
            end   
        end
        
        function substract_baseline(varargin)
            % substract baseline
            % note: there are different baseline methods, see the baseline
            % function.
            this_sweepset=varargin{1};
            this_sweepset.settings.baseline_info.substracted=~ this_sweepset.settings.baseline_info.substracted;
        end        
              
        function average_trace=get.average_trace(this_sweepset)
            average_trace=mean(squeeze(this_sweepset.data(:,1,this_sweepset.sweep_selection)),2);
            
            if this_sweepset.settings.average_smooth>0
                average_trace=smooth(average_trace,this_sweepset.settings.average_smooth*this_sweepset.sampling_frequency);
            end
            
        end      
        
        function smooth_average(this_sweepset, smooth_factor)
             this_sweepset.settings.average_smooth=round(smooth_factor); %will be automatically updated because of the listener to settings
        end
        
        function smooth_trace(this_sweepset, input)
        % function will smooth the traces (removed noise) using a sliding window based on input*sampling_frequency.    
        
            if ischar(input)
                if strcmp(input,'undo')
                    this_sweepset.settings.smoothed=false;
                    disp('smoothing undone')
                else
                    disp('unrecognized input')
                end
            else
                this_sweepset.settings.smoothed=true;
                this_sweepset.settings.smooth_factor=input;
                disp(['Data smoothed by ' num2str(input) 'ms']);
            end
            
        end
        
        function output_data(this_sweepset, options, matrix_name)
        % for output of data for further analysis or figure design.
        
            switch options
                case 'whole_trace'
                    output_matrix=zeros(length(this_sweepset.X_data),sum(this_sweepset.sweep_selection)+1);
                    output_matrix(:,1)=this_sweepset.X_data;
                    output_matrix(:,2:end)=squeeze(this_sweepset.data(:,1,this_sweepset.sweep_selection));
                    assignin('base',matrix_name,output_matrix);
                case 'average'
                    output_matrix=zeros(length(this_sweepset.X_data),2);
                    output_matrix(:,1)=this_sweepset.X_data;
                    output_matrix(:,2)=this_sweepset.average_trace;
                    assignin('base',matrix_name,output_matrix);
                otherwise
                    disp([options ' is not an available option'])
            end
            
        end
        
        function remove_artifacts(this_sweepset)
            % This function will remove those anoying 'spikes' caused by
            % the perfusion pump (in my case), but it can later be adapted
            % to remove artifacts in general.
            
            % This function if not currently working.
            
            for i=1:this_sweepset.number_of_sweeps
                active_trace=this_sweepset.data(:,1,i);
                for a=2:length(active_trace)-4
                    for b=1:round(this_sweepset.sampling_frequency/2) %spike still removed if less than 0.5 ms long
                        if abs(active_trace(a)-active_trace(a-1))>=200/this_sweepset.sampling_frequency %basically 20pA/0.1ms is max change
                            if abs(active_trace(a+3)-active_trace(a-1))<=200/this_sweepset.sampling_frequency %basically it has to be a spike and not stay up or down (actual chage)
                            active_trace(a)=active_trace(a-1);
                            end
                        end
                    end   
                end
                this_sweepset.data(:,1,i)=active_trace;
            end
            
             for i=1:length(this_sweepset.handles.all_sweeps)
                set(this_sweepset.handles.all_sweeps(i),'YData',squeeze(this_sweepset.data(:,1,i)));
             end
            
        end
        
        function baseline=get.baseline(this_sweepset)
            
            switch this_sweepset.settings.baseline_info.method
                case 'standard'
                    % standard is substract value between start and end
                    start_point=this_sweepset.settings.baseline_info.start*this_sweepset.sampling_frequency;
                    end_point=this_sweepset.settings.baseline_info.end*this_sweepset.sampling_frequency;
                    baseline=mean(this_sweepset.original_data(start_point:end_point,1,:),1);            
                    baseline=repmat(baseline,length(this_sweepset.data(:,1,1)),1);
                    baseline=reshape(baseline,size(this_sweepset.data));
                case 'whole_trace'
                    baseline=mean(this_sweepset.original_data(:,1,:),1);            
                    baseline=repmat(baseline,length(this_sweepset.data(:,1,1)),1);
                    baseline=reshape(baseline,size(this_sweepset.data));
                case 'moving_average_1s'
                    baseline=zeros(size(this_sweepset.data));
                    for i=1:length(this_sweepset.data(1,1,:))
                        baseline(:,1,i)=smooth(this_sweepset.original_data(:,1,i),this_sweepset.sampling_frequency*10^3); %smooth over 1sec sliding window
                    end
                otherwise
                    disp('Baseline substraction method not recognized.');
                    baseline=0;
            end
            
        end
        
        function base_data=get.base_data(this_sweepset)
            % This getter function is run when settings about baseline
            % substraction or other data manipulations are changed. It
            % takes the original data and performs the requested
            % manipulations.
            
            % first looking at the baseline:
            switch this_sweepset.settings.baseline_info.substracted
                case true
                    base_data=this_sweepset.original_data-this_sweepset.baseline;
                case false
                    base_data=this_sweepset.original_data;
            end
            
            % now checking if the traces are suposed to be smooth
            input=this_sweepset.settings.smooth_factor;
            if this_sweepset.settings.smoothed==true
                    for i=1:length(this_sweepset.data(1,1,:))
                    base_data(:,1,i)=smooth(base_data(:,1,i),this_sweepset.sampling_frequency*input);
                    end
            end
            
            % here we should add any other manipulations that can be
            % performed on the base data
            
        end
        
    end
    
%%%%%%%%%%%%%%%%%%%%%% Callbacks & other functions%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Access = private) 
        
        function key_press(this_sweepset, scr, ~)
        % controls user keyboard input
        key=double(get(this_sweepset.handles.figure,'CurrentCharacter'));
        
            switch key
                case 29  %Right arrow (next sweep)
                    move_sweep(this_sweepset,this_sweepset.current_sweep+1);
                case 28  %Left arrow (previous sweep)
                    move_sweep(this_sweepset,this_sweepset.current_sweep-1);
                case 115 %'S' (select sweep)
                    this_sweepset.sweep_selection(this_sweepset.current_sweep)=1;
                case 114 %'R' (reject sweep)
                    this_sweepset.sweep_selection(this_sweepset.current_sweep)=0;
                case 13  %ENTER print selection
                     disp_text=[get(this_sweepset.handles.figure,'Name') ,' current selection:'];
                     disp(disp_text);
                     disp(this_sweepset.sweep_selection);
                case 97  %'A' plot average trace
                    status=get(this_sweepset.handles.average_trace,'visible');
                    if strcmp(status,'off')
                        set(this_sweepset.handles.average_trace,'visible','on')
                    else
                        set(this_sweepset.handles.average_trace,'visible','off')
                    end
                case 113 %'Q' substract baseline
                    this_sweepset.substract_baseline
                case 122 %'Z' show all other sweeps in background
                    status=get(this_sweepset.handles.all_sweeps(1),'visible');
                    if strcmp(status,'off')
                        set(this_sweepset.handles.all_sweeps,'visible','on')
                    else
                        set(this_sweepset.handles.all_sweeps,'visible','off')
                    end
                case 109 %'M' measure
                    this_sweepset.handles.measurement=measure(this_sweepset);
                case 102 %'F' firing frequency
                    this_sweepset.handles.firing_frequency=firing_frequency(this_sweepset);
                case 27 % Esc, reset axis for complete overview
                    floor=min(min(this_sweepset.data))-10;
                    roof=max(max(this_sweepset.data))+10;
                    disp_right=round(length(this_sweepset.data(:,1,1))/this_sweepset.sampling_frequency);
                    axis([0 disp_right floor roof])
                case 99 % 'C', open trace combiner
                    combiner_1=trace_combiner;
                    assignin('base','combiner_1',combiner_1);
            end
            
            notify(this_sweepset,'state_change')
        end
        
        function plot_update(this_sweepset, ev, ~)
            % Will listen to changed variabled and update other accordingly
            
            switch ev.Name
                case 'sweep_selection'
                    notify(this_sweepset,'selection_change')
                    notify(this_sweepset,'state_change')
                    % update all plots that are dependend on this variable
                    set(this_sweepset.handles.average_trace,'YData',this_sweepset.average_trace);
                    for i=1:length(this_sweepset.sweep_selection)
                        if this_sweepset.sweep_selection(i)
                            this_sweepset.handles.all_sweeps(i).Color=[0 0 1];
                        else
                            this_sweepset.handles.all_sweeps(i).Color=[0 0.7 1];
                        end
                    end
                    
                case 'settings'
                    this_sweepset.data=this_sweepset.base_data;
                    set(this_sweepset.handles.average_trace,'YData',this_sweepset.average_trace);
                    set(this_sweepset.handles.current_sweep,'YData',this_sweepset.data(:,1,this_sweepset.current_sweep));
                    for i=1:length(this_sweepset.handles.all_sweeps)
                        set(this_sweepset.handles.all_sweeps(i),'YData',squeeze(this_sweepset.data(:,1,i)));
                    end
                    set(this_sweepset.handles.average_trace,'YData',this_sweepset.average_trace);
                    
                    notify(this_sweepset,'state_change')
            end
        end
        
        function click_on_sweep(this_sweepset, clicked_sweep, click_info)
            % Deals with both left and right clicks on all sweeps.
            % So later should include check for average sweep and current
            % sweep, because those are plotted on top.
            
            % Making sure other functions know where the user clicked
            this_sweepset.click_info=click_info;
            
            if click_info.Button==1 && ~ischar(clicked_sweep.UserData)
                this_sweepset.move_sweep(clicked_sweep.UserData);
            end
            
            if click_info.Button==3
                this_sweepset.current_sweep_R=clicked_sweep.UserData;
                % Figure out what was clicked
                if ischar(clicked_sweep.UserData)
                    if strcmp(clicked_sweep.UserData,'current_sweep')
                        this_sweepset.current_sweep_R=this_sweepset.current_sweep;
                    elseif strcmp(clicked_sweep.UserData,'average_trace')
                        this_sweepset.current_sweep_R='average_trace';
                    else
                        error('no idea what was clicked')
                    end
                else
                     this_sweepset.current_sweep_R=clicked_sweep.UserData;
                end
                
                % Adapting the drop down to only show usefull options
                if ~ischar(this_sweepset.current_sweep_R) && this_sweepset.sweep_selection(this_sweepset.current_sweep_R)
                     set(this_sweepset.handles.drop_down.m1,'Visible','off')
                     set(this_sweepset.handles.drop_down.m2,'Visible','on')
                elseif ~ischar(this_sweepset.current_sweep_R)
                    set(this_sweepset.handles.drop_down.m1,'Visible','on')
                    set(this_sweepset.handles.drop_down.m2,'Visible','off')
                end
                
            end
        end
        
        function close_req(this_sweepset, scr, ev)
            % just to make sure that not only this figure, but also it's associated
            % windows are closed.
            
            notify(this_sweepset,'sweepset_closed')

            if ishandle(this_sweepset.handles.measurement)
                delete(this_sweepset.handles.measurement);
            end
            
            if ishandle(this_sweepset.handles.firing_frequency)
                delete(this_sweepset.handles.firing_frequency);
            end
            
            delete(this_sweepset.handles.figure)
            delete(this_sweepset)
        end
        
        function sweep_context(this_sweepset, scr, ev)
            % Drop down menu when the user righ-clicks a sweep
            
            switch scr.Label
                case 'include sweep'
                    this_sweepset.sweep_selection(this_sweepset.current_sweep_R)=true;
                    notify(this_sweepset,'state_change')
                    notify(this_sweepset,'selection_change')
                case 'reject sweep'
                    this_sweepset.sweep_selection(this_sweepset.current_sweep_R)=false;
                    notify(this_sweepset,'state_change')
                    notify(this_sweepset,'selection_change')
                case 'display average'
                     status=get(this_sweepset.handles.average_trace,'visible');
                    if strcmp(status,'off')
                        set(this_sweepset.handles.average_trace,'visible','on')
                    else
                        set(this_sweepset.handles.average_trace,'visible','off')
                    end
                case 'display all sweeps'
                    status=get(this_sweepset.handles.all_sweeps(1),'visible');
                    if strcmp(status,'off')
                        set(this_sweepset.handles.all_sweeps,'visible','on')
                    else
                        set(this_sweepset.handles.all_sweeps,'visible','off')
                    end
                case 'standard'
                    this_sweepset.settings.baseline_info.method='standard';
                case 'whole trace'
                    this_sweepset.settings.baseline_info.method='whole_trace';
                case 'moving average 1s'
                    this_sweepset.settings.baseline_info.method='moving_average_1s';
                case 'refocus'
                    floor=min(min(this_sweepset.data))-10;
                    roof=max(max(this_sweepset.data))+10;
                    disp_right=round(length(this_sweepset.data(:,1,1))/this_sweepset.sampling_frequency);
                    axis([0 disp_right floor roof])
                case 'combine sweepsets'
                    combiner_1=trace_combiner;
                    assignin('base','combiner_1',combiner_1);
                case 'measure peak'
                    % Figure out where and on what was clicked
                    x_click_location=this_sweepset.click_info.IntersectionPoint(1);
                    
                    % Check if the average trace or any other trace should
                    % be measured.
                    if strcmp(this_sweepset.click_info.Source.UserData,'average_trace')
                        selection_mode='average';
                    else
                        selection_mode='current';
                    end
                    
                     this_sweepset.handles.measurement=measure(this_sweepset,'start interval',[x_click_location-20, x_click_location+20],'mode',selection_mode);
                case 'smooth 1ms'
                    % figure out if cliced on average trace or other trace
                    if strcmp(this_sweepset.click_info.Source.UserData,'average_trace')
                        this_sweepset.smooth_average(1);
                        set(this_sweepset.handles.average_drop_down.m2,'label','undo smooth')
                    else
                        this_sweepset.smooth_trace(1);
                        set(this_sweepset.handles.drop_down.m3,'label','undo smooth')
                    end
                case 'undo smooth'
                    if strcmp(this_sweepset.click_info.Source.UserData,'average_trace')
                        this_sweepset.smooth_average(0);
                        set(this_sweepset.handles.average_drop_down.m2,'label','smooth 1ms')
                    else
                        this_sweepset.smooth_trace('undo');
                        set(this_sweepset.handles.drop_down.m3,'label','smooth 1ms')
                    end
                case 'export data'
                    output_matrix=inputdlg('Ouput matrix name: ');
                    output_matrix=char(output_matrix{1});
                    output_matrix(output_matrix==' ')='_'; %removing spaces
                    if isstrprop(output_matrix(1),'digit')
                        % variables can not start with a number
                        output_matrix=['D_', output_matrix];
                    end
                    this_sweepset.output_data('whole_trace',output_matrix);
                    disp('Data stored in workspace')
                case 'export average'
                    output_matrix=inputdlg('Ouput matrix name: ');
                    output_matrix=char(output_matrix{1});
                    if isstrprop(output_matrix(1),'digit')
                        % variables can not start with a number
                        output_matrix=['D_', output_matrix];
                    end
                    output_matrix(output_matrix==' ')='_'; %removing spaces
                    this_sweepset.output_data('average',output_matrix);
                    disp('Data stored in workspace')
            end  
        end 
    end
    
    events
      state_change      % reports anything that changes (fires all the time, best not to use to often)
      selection_change  % only fires when selected sweep changes
      baseline_change   % only fires when the baseline changes
      sweepset_closed   % fires when this sweepset window is closed
    end
        
        
end
    






