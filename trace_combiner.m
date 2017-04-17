classdef trace_combiner < handle
    %TRACE_COMBINER combines average traces from different sweepset objects
    %into one figure for easy visualization.
    
    properties (SetObservable)
        linked_objects          % Handles to the linked sweepsets
        plot_handles            % Handles to the plots
        legend_handle           % Handle to the figure legend
        figure_handle           % Handle to the figure 
        X_data                  % X axis data (ms)
        Y_data                  % All traces
        Header_data             % Header data about the sweepsets
        data_names              % Filenames of the linked sweepsets
        data_selection          % Logical of selected data
        current_trace           % Currently selected trace
        settings                % Other settings
    end
    
    properties
        plot_listeners          % Listen to the average traces, need to be updated if they are changed.
        selection_listener      % Check if data selection changes  
    end
    
    methods
        
        function this_trace_combiner=trace_combiner(varargin)
        % Constructor.
            
        % Deal with input arguments
        objects_found=false;
        for i=1:length(varargin)
            if strcmp(varargin{i},'object_list')
                linked_objects=varargin{i+1};
                assignin('base','testera',linked_objects)
                objects_found=true;
                np_sweepsets=size(linked_objects);
                np_sweepsets=np_sweepsets(2);
            end
        end
        
        if ~objects_found
            % see if base created any sweepsets
            all_objects=get(0,'children');
            np_sweepsets=0;
            for i=1:length(all_objects)
                object_name=all_objects(i).Name;
                if length(object_name)>4 && strcmp(all_objects(i).Name(end-3:end),'.abf')
                    np_sweepsets=np_sweepsets+1;
                    % Yes, we check if the objects are sweepsets using the
                    % window name.
                    
                    linked_objects{np_sweepsets}=getappdata(all_objects(i),'object');
                   
                end
            end
        end
            
            disp(['Number of sweepsets found: ',num2str(np_sweepsets)]);
            this_trace_combiner.linked_objects=linked_objects;
             
            %making the figure
            this_trace_combiner.figure_handle=figure();
            hold on
            set(this_trace_combiner.figure_handle,'CloseRequestFcn',@this_trace_combiner.close_req)
            
            % Linking all open sweepsets
            for i=1:np_sweepsets  
                this_trace_combiner.data_names{i}=linked_objects{i}.filename; % store the filenames
                plot_listeners(i)=addlistener(linked_objects{i},'state_change',@this_trace_combiner.update_plot);
                this_trace_combiner.Y_data{i}=linked_objects{i}.average_trace;
                this_trace_combiner.X_data{i}=linked_objects{i}.X_data;
                this_trace_combiner.Header_data(i).clamp_type=linked_objects{i}.clamp_type;
                this_trace_combiner.Header_data(i).sampling_frequency=linked_objects{i}.sampling_frequency;
            end
            this_trace_combiner.plot_listeners=plot_listeners;
            
            % Checking if all sweepsets have the same clamp type
            different_clamp=false;
            for i=2:np_sweepsets
                if ~strcmp(this_trace_combiner.Header_data(i).clamp_type, this_trace_combiner.Header_data(i-1).clamp_type)
                    disp('NOTE: Not all sweepsets have the same clamp type')
                    different_clamp=true;
                end
            end
            
            % Plotting on one or two y-axes
            for i=1:np_sweepsets
                if different_clamp && strcmp(this_trace_combiner.Header_data(i).clamp_type,'Voltage (mV)');
                    yyaxis right
                elseif different_clamp
                    yyaxis left
                end  
                this_trace_combiner.plot_handles(i)=plot(linked_objects{i}.X_data,linked_objects{i}.average_trace);
                this_trace_combiner.Header_data(i).color=get(this_trace_combiner.plot_handles(i),'Color'); % Store the original color
                set(this_trace_combiner.plot_handles(i),'DisplayName',linked_objects{i}.filename,'ButtonDownFcN',@this_trace_combiner.click_on_trace); % filename in the trace (for auto legend) and now you can click on the traces
            end
                
            % Figure axis
            xlabel('time (ms)')
            if different_clamp
                yyaxis left
                ylabel('Current (pA)')
                yyaxis right
                ylabel('Voltage (mV)')
            else
                ylabel(linked_objects{1}.clamp_type)
            end

            % Figure legend
            this_trace_combiner.legend_handle=legend(this_trace_combiner.data_names,'Location','southeast');

            % Find some other variables
            this_trace_combiner.data_selection=true(1,np_sweepsets);
            
            % Adding callbacks and listeners
            this_trace_combiner.selection_listener=addlistener(this_trace_combiner,'data_selection','PostSet',@this_trace_combiner.update_plot);
        
        end
       
        function output_data(this_trace_combiner, matrix_name)
            % Collecting all the data and storing it in an output matrix
            i=1;
            j=1;
            while ~this_trace_combiner.data_selection(i)
                i=i+1;
                j=i+1; 
                if i>length(this_trace_combiner.data_selection)
                    disp('no traces selected')
                    return
                end
            end
                

            
            output_matrix=zeros(length(this_trace_combiner.X_data{j}),sum(this_trace_combiner.data_selection)+1); %for a start
            previous_X_data=this_trace_combiner.X_data{j};
            output_matrix(:,1)=previous_X_data;
            
            l=1;
            for i=1:length(this_trace_combiner.data_selection)
                while l<=length(this_trace_combiner.data_selection) && ~this_trace_combiner.data_selection(l) 
                    l=l+1; % skip unselected traces
                end

                done=false;
                if l>length(this_trace_combiner.data_selection)
                    done=true;
                else
                    current_X_data=this_trace_combiner.X_data{l};
                end
                
                if isequal(current_X_data, previous_X_data) && ~done %these traces will fit on the same X_data, store them next to each other
                    output_matrix(:,i+1)=this_trace_combiner.Y_data{l};
                    l=l+1;
                elseif ~done % They don't fit next to each other, include seperate X_data
                    
                    error('Traces not on the same X_axis or different sampling frequency.')
                    
                end
                
                previous_X_data=current_X_data;
            end
            
            % TODO, write something to organise this matrix and the
            % different X_axes
                
            assignin('base',matrix_name,output_matrix);
        end 
        
    end
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Callbacks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = private)
        
        function update_plot(this_trace_combiner, ~, ~)
            % Update plot after linked sweepsets or settings change
            % Also checking if the linked sweepsets still exist.
            for i=1:length(this_trace_combiner.plot_handles)
                if isvalid(this_trace_combiner.linked_objects{i}) && this_trace_combiner.data_selection(i)
                    av_plot=this_trace_combiner.linked_objects{i}.average_trace; %otherwise it will recalculate twice (because it is a dependend variable)
                    set(this_trace_combiner.plot_handles(i),'YData',av_plot,'Visible','on');
                    this_trace_combiner.Y_data(i)={av_plot};
                elseif isvalid(this_trace_combiner.linked_objects{i})
                    set(this_trace_combiner.plot_handles(i),'YData',this_trace_combiner.linked_objects{i}.average_trace,'Visible','off');
                elseif this_trace_combiner.data_selection(i)
                    set(this_trace_combiner.plot_handles(i),'Visible','on');
                else
                    set(this_trace_combiner.plot_handles(i),'Visible','off');
                end
            end 
        end
        
        function click_on_trace(this_trace_combiner, clicked_plot, click_info)
            % The user clicked on a trace
            np_sweepsets=length(this_trace_combiner.data_selection);
            
            if click_info.Button==1 %left mouse button
                for i=1:np_sweepsets
                    if strcmp(clicked_plot.DisplayName, this_trace_combiner.data_names{i})
                        this_trace_combiner.current_trace=i;
                        clicked_plot.Color=[0 1 0];
                        if isvalid(this_trace_combiner.linked_objects{i})
                            figure(this_trace_combiner.linked_objects{i}.handles.figure)
                        else
                            % Try and open the file?
                            if exist(clicked_plot.DisplayName,'file')
                                this_trace_combiner.linked_objects{i}=sweepset('filename',clicked_plot.DisplayName);
                                
                                % Should check if this file is really the
                                % correct trace and display it properly.
                                % (e.g. baseline subtracted etc...)
                                
                                this_sweep_combiner.plot_listeners(i)=addlistener(this_trace_combiner.linked_objects{i},'state_change',@this_trace_combiner.update_plot);
                            end
                        end
                    else
                        set(this_trace_combiner.plot_handles(i),'Color',this_trace_combiner.Header_data(i).color);     
                    end
                end
            elseif click_info.Button==3
                for i=1:np_sweepsets
                    if strcmp(clicked_plot.DisplayName, this_trace_combiner.data_names{i})
                        this_trace_combiner.current_trace=0;
                        this_trace_combiner.data_selection(i)=false;
                    end
                end
            end
            
            update_plot(this_trace_combiner);
        end
        
        function close_req(this_trace_combiner, ev, ~)
            % Tidy closing or the object
            for i=1:length(this_trace_combiner.plot_listeners)
                delete(this_trace_combiner.plot_listeners(i));
            end
            
            delete(this_trace_combiner.figure_handle);
            delete(this_trace_combiner.selection_listener);
            delete(this_trace_combiner);
            
        end
        
    end
    
end

