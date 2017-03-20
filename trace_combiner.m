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
    end
    
    properties
        plot_listeners          % Listen to the average traces, need to be updated if they are changed.
        selection_listener      % Check if data selection changes  
    end
    
    methods
        
        function this_trace_combiner=trace_combiner(varargin)
        % Constructor.
        
            all_objects=get(0,'children');
            np_sweepsets=0;
            
            for i=1:length(all_objects)
                object_name=all_objects(i).Name;
                if length(object_name)>4 && strcmp(all_objects(i).Name(end-3:end),'.abf')
                    np_sweepsets=np_sweepsets+1;
                    % Yes, we check if the objects are sweepsets using the
                    % window name.
                    
                    linked_objects(np_sweepsets)=getappdata(all_objects(i),'object');
                   
                end
            end
            disp(['Number of sweepset found: ',num2str(np_sweepsets)]);
            this_trace_combiner.linked_objects=linked_objects;
             
            %making the figure
            this_trace_combiner.figure_handle=figure();
            hold on
            set(this_trace_combiner.figure_handle,'CloseRequestFcn',@this_trace_combiner.close_req)
            
            % Linking all open sweepsets
            for i=1:np_sweepsets  
                this_trace_combiner.data_names{i}=linked_objects(i).filename; % store the filenames
                plot_listeners(i)=addlistener(linked_objects(i),'state_change',@this_trace_combiner.update_plot);
                this_trace_combiner.Y_data{i}=linked_objects(i).average_trace;
                this_trace_combiner.X_data{i}=linked_objects(i).X_data;
                this_trace_combiner.Header_data(i).clamp_type=linked_objects(i).clamp_type;
                this_trace_combiner.Header_data(i).sampling_frequency=linked_objects(i).sampling_frequency;
            end
            this_trace_combiner.plot_listeners=plot_listeners;
            
            % Checking if all sweepsets have the same clamp type
            different_clamp=false;
            for i=2:np_sweepsets
                if ~strcmp(this_trace_combiner.Header_data(i).clamp_type, this_trace_combiner.Header_data(i-1).clamp_type)
                    disp('NOTE: note all sweeps have the same clamp type')
                    different_clamp=true;
                end
            end
            
            % Plotting on one or two y-axes
            for i=1:np_sweepsets
                if different_clamp && strcmp(this_trace_combiner.Header_data(i).clamp_type,'Voltage (mV)');
                    yyaxis right
                else
                    yyaxis left
                end  
                this_trace_combiner.plot_handles(i)=plot(linked_objects(i).X_data,linked_objects(i).average_trace);
                set(this_trace_combiner.plot_handles(i),'DisplayName',linked_objects(i).filename); % filename in the trace (for auto legend)
            end
                
            % Figure axis
            xlabel('time (ms)')
            if different_clamp
                yyaxis left
                ylabel('Current (pA)')
                yyaxis right
                ylabel('Voltage (mV)')
            else
                ylabel(linked_objects(1).clamp_type)
            end

            % Figure legend
            this_trace_combiner.legend_handle=legend(this_trace_combiner.data_names,'Location','southeast');

            % Find some other variables
            this_trace_combiner.data_selection=true(1,np_sweepsets);
            
            % Adding callbacks and listeners
            this_trace_combiner.selection_listener=addlistener(this_trace_combiner,'data_selection','PostSet',@this_trace_combiner.update_plot);
        
        end
       
        function output_data(this_trace_combiner, matrix_name)
            output_matrix=zeros(length(this_trace_combiner.X_data),sum(this_trace_combiner.data_selection)+1);
            output_matrix(:,1)=this_trace_combiner.X_data;
            output_matrix(:,2:end)=this_trace_combiner.Y_data(:,this_trace_combiner.data_selection);
            assignin('base',matrix_name,output_matrix);
        end
        
        
    end
    
    methods (Access = private)
        
        function update_plot(this_trace_combiner, ev, ~)
            % Update plot after linked sweepsets or settings change
            % Also checking if the linked sweepsets still exist.
            for i=1:length(this_trace_combiner.plot_handles)
                if isvalid(this_trace_combiner.linked_objects(i)) && this_trace_combiner.data_selection(i)
                    set(this_trace_combiner.plot_handles(i),'YData',this_trace_combiner.linked_objects(i).average_trace,'Visible','on');
                elseif isvalid(this_trace_combiner.linked_objects(i))
                    set(this_trace_combiner.plot_handles(i),'YData',this_trace_combiner.linked_objects(i).average_trace,'Visible','off');
                elseif this_trace_combiner.data_selection(i)
                    set(this_trace_combiner.plot_handles(i),'Visible','on');
                else
                    set(this_trace_combiner.plot_handles(i),'Visible','off');
                end
            end 
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

