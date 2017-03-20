classdef trace_combiner < handle
    %TRACE_COMBINER combines average traces from different sweepset objects
    %into one figure for easy visualization.
    
    properties
        linked_objects          % Handles to the linked sweepsets
        plot_handles            % Handles to the plots
        figure_handle           % Handle to the figure
        plot_listeners          % Listen to the average traces, need to be updated if they are changed.
        X_data                  % X axis data (ms)
        Y_data                  % All traces
        data_selection          % Logical of selected data
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
                    
                    linked_objects(np_sweepsets)=getappdata(all_objects(i),'object')
                   
                end
            end
            disp(['Number of sweepset found: ',num2str(np_sweepsets)]);
            this_trace_combiner.linked_objects=linked_objects;
             
        %making the figure
        this_trace_combiner.figure_handle=figure();
        hold on
        set(this_trace_combiner.figure_handle,'CloseRequestFcn',@this_trace_combiner.close_req)
        % Add the closeFCN here (destruct object when figure is closed)
        % Oh and the listeners off course!
        
            for i=1:np_sweepsets
                this_trace_combiner.plot_handles(i)=plot(linked_objects(i).X_data,linked_objects(i).average_trace);
                plot_listeners(i)=addlistener(linked_objects(i),'state_change',@this_trace_combiner.update_plot);
                this_trace_combiner.Y_data(:,i)=linked_objects(i).average_trace; % Will only work if they are the same length!
            end
            this_trace_combiner.plot_listeners=plot_listeners;
            
        % Figure axis
            xlabel('time (ms)')
            ylabel(linked_objects(1).clamp_type)              
        
        % Find some other variables
        this_trace_combiner.X_data=linked_objects(i).X_data; %Sort of based on the fact that all traces sampled at the same frequency. Which is usually, but not necessarily, true. 
        this_trace_combiner.data_selection=true(1,np_sweepsets);
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
            for i=1:length(this_trace_combiner.plot_handles)
                set(this_trace_combiner.plot_handles(i),'YData',this_trace_combiner.linked_objects(i).average_trace);
            end
        end
        
        function close_req(this_trace_combiner, ev, ~)
            for i=1:length(this_trace_combiner.plot_listeners)
                delete(this_trace_combiner.plot_listeners(i));
            end
            
            delete(this_trace_combiner.figure_handle);
            delete(this_trace_combiner);
            
        end
        
    end
    
end

