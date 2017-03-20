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
    %       - 'user_select', ('on'/'off')   | UI for file selection
    %       - 'filename', 'path/filename'   | open selected file
    %
    %   Made by Johannes de Jong, j.w.dejong@berkeley.edu
    
    
    properties (SetObservable)
        filename            % .abf file
        file_header         % provide by abfload
        data                % sweepset as it is currently used
        original_data       % sweepset as is was imported at startup
        X_data              % X_axis
        clamp_type          % Voltage or current clamp
        sampling_frequency  % in KHz           
        number_of_sweeps    % number of sweeps in the set
        handles             % Of all aspects of the figure
        sweep_selection     % sweeps can be either rejected or selected by the user
        current_sweep       % the currently active sweep
        outside_world       % used when this objects thinks the outside world might want to update something.
        settings            % struct with settings, used for interaction with user and GUI
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
                % open input filename
                if strcmp(varargin{i},'filename')
                    this_sweepset.filename=varargin{i+1};
                    [this_sweepset.data, sampling_interval, this_sweepset.file_header]=abfload(this_sweepset.filename);
                    this_sweepset.sampling_frequency=10^3/sampling_interval; % The sampling frequency in kHz 
                end
                
                % allow the user to select file
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
                
            % Plot all the sweeps, but only the selected sweep is visible            
            this_sweepset.handles.all_sweeps=plot(this_sweepset.X_data,squeeze(this_sweepset.data(:,1,:)),'b','visible','off');
            this_sweepset.handles.current_sweep=plot(this_sweepset.X_data,this_sweepset.data(:,1,this_sweepset.current_sweep),'r');
            this_sweepset.handles.average_trace=plot(this_sweepset.X_data,this_sweepset.average_trace,'g','visible','off');
            
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
                set(this_sweepset.handles.current_sweep,'YData',this_sweepset.data(:,1,this_sweepset.current_sweep));
                notify(this_sweepset,'state_change')
            end   
        end
        
        function substract_baseline(this_sweepset)
            % substract baseline
            % note: there are different baseline methods, see the baseline
            % function.
            figure(this_sweepset.handles.figure)
            
            this_sweepset.settings.baseline_info.substracted=~ this_sweepset.settings.baseline_info.substracted;
        end        
              
        function average_trace=get.average_trace(this_sweepset)
            average_trace=mean(squeeze(this_sweepset.data(:,1,this_sweepset.sweep_selection)),2);
            
            if this_sweepset.settings.average_smooth>0
                average_trace=smooth(average_trace,this_sweepset.settings.average_smooth);
            end
            
        end      
        
        function smooth_average(this_sweepset, smooth_factor)
             SF=this_sweepset.sampling_frequency;
             this_sweepset.settings.average_smooth=round(smooth_factor)*SF; %will be automatically updated because of the listener to settings
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
                    base_data=this_sweepset.original_data; %But this is wrong, because trace can be smoothed
            end
            
            % now checking if the traces are suposed to be smooth
            input=this_sweepset.settings.smooth_factor;
            if this_sweepset.settings.smoothed==true
                    for i=1:length(this_sweepset.data(1,1,:))
                    base_data(:,1,i)=smooth(base_data(:,1,i),this_sweepset.sampling_frequency*input);
                    end
            end
            
            
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
                    trace_combiner
            end
            
            notify(this_sweepset,'state_change')
        end
        
        function plot_update(this_sweepset, ev, ~)
            % Will listen to changed variabled and update other accordingly
            
            switch ev.Name
                case 'sweep_selection'
                    notify(this_sweepset,'selection_change')
                    % update all plots that are dependend on this variable
                    set(this_sweepset.handles.average_trace,'YData',this_sweepset.average_trace);
                case 'settings'
                    notify(this_sweepset,'state_change')
                    this_sweepset.data=this_sweepset.base_data;
                    set(this_sweepset.handles.average_trace,'YData',this_sweepset.average_trace);
                    set(this_sweepset.handles.current_sweep,'YData',this_sweepset.data(:,1,this_sweepset.current_sweep));
                    for i=1:length(this_sweepset.handles.all_sweeps)
                        set(this_sweepset.handles.all_sweeps(i),'YData',squeeze(this_sweepset.data(:,1,i)));
                    end
                    set(this_sweepset.handles.average_trace,'YData',this_sweepset.average_trace);
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
        
    end
    
    events
      state_change      % reports anything that changes (fires all the time, best not to use to often)
      selection_change  % only fires when selected sweep changes
      baseline_change   % only fires when the baseline changes
      sweepset_closed   % fires when this sweepset window is closed
    end
        
        
end
    






