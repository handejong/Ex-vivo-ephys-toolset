# Ex-vivo-ephys-toolset
A series of Matlab scripts to import analyze slice electrophysiology recordings collected with Pclamp (Molecular Devices).

The toolset is based on 'abfload.m', which imports .abf files into matlab arrays. Abfload was made by Harald Hentschke and is orriginally available here: https://www.mathworks.com/matlabcentral/fileexchange/6190-abfload.

# Installation:
Make sure the following files are available on the Matlab path:

      abfload.m                                    - For import of .abf files. Made by Harald Hentschke.
      pvpmod.m                                     - Deals with varargin in abfload.m. Made by Ulrich Egert
      sweepset.m                                   - Describes the sweepset class. Made by Han de Jong
      measure.m & measure.fig                      - GUI for amplitude measurements of events
      firing_frequency.m & firing_frequency.fig    - GUI for measuring frequency of events
      Bearphys.m & Bearphys.fig                    - GUI for interaction with sweepset.m.

# How to get started using the Bearphys GUI
Type:

      >>Bearphys
      
This should open the GUI. Note that use of the GUI should not prevent additional use of the command line interface. The GUI should support multiple sweepset objects at the same time. However, glitches can occur when switching between multiple figures as the user and the GUI sometimes disagree on what the active figure is. Use 'S' and 'R' to select and reject sweeps.

# How to get started using comand line interface:
The basis of the toolkit is the sweepset object into which .abf recordings are loaded. A sweepset class is initiated by the command:
      
            >> output_sweepset=sweepset('user_select','on')
            
To open a file browser where the user can select a .abf file. Alternatively one can specify the filename as follows:

            >> output_sweepset=sweepset('filename','filename.abf')

This will create a sweepset object named 'output_sweepset'. The first sweep is presented in a figure and data about the dataset is printed to the command line. The following command prints information about the sweepset (such as the sampling frequency):

            >> output_sweepset.file_header

If the window that displays the sweepset is active. One can scroll through the different sweeps using the arrow keys. Alternatively the following keypresses are currently supported:

          arrow keys left and right:  Scroll trough different sweeps
          Q:                          Substract baseline (see baseline method below)
          A:                          Display average sweep (uses only 'selected', not 'rejected' sweeps)
          Z:                          Display entire dataset in background
          S:                          Select sweeps (sweeps are selected by default).
          R:                          Reject sweep (meaning that the sweep will not be taken into account in any analysis)
          ENTER:                      Print the current sweep selection to the commmand line
          M:                          Open measurement GUI for measurement of amplitude of peaks.
          F:                          Open GUI for measuring event frequency
	  C:                          Will start the ‘trace combiner object’ which combines average traces from different sweepsets.
          Esc:                        Reset Y and X axis for complete overview of data

Note that Matlab figures only register key presses when they are active and when no figure tools (such as zoom or scroll) are active. To deactive a figure tool, click it again on the figure toolbar.

Using S and R one can select and reject individual sweeps (for instance because they contain artifacts). The calculated average trace, as well as measurements by seperate GUIs, should be automatically updated. It is also possible to manually set the sweep selection. In the Matlab workspace browse to the variable output_sweepset.sweep_selection. This is a logical. Select or recject sweeps by typing 'false', 'true', '1' or '0' below the sweep number.

The toolkit currently supports three ways of baseline subtraction. They are 'standard', 'whole_trace' & 'moving_average_1s';

            >> output_sweepset.settings.baseline_info.start=10; %ms
            >> output_sweepset.settings.baseline_info.end=100; %ms
            >> this_sweepset.settings.baseline_info.method='standard';
            >> output_sweepset.settings.baseline_info.substracted=true;

This will substract the baseline (defined as the average value between 10ms and 100ms) from each sweep individually. If 'baseline_info.start' and 'baseline_info.end' are not manually set, they are 1ms and 100ms by default. The method is also set to 'standard' by default. Instead of manually setting 'baseline_info.substracted' to true, one can press 'Q' on the active figure or type:

            >> output_sweepset.substract_baseline;
       
This will toggle baseline substraction. Substraction method 'whole trace':

            >> output_sweepset.settings.baseline_info.method='whole_trace';
            note: this just sets the method. Toggle baseline subtraction as above.
            
This will subtract the average of each sweep from itself. 'moving_average_1s' is ideal to remove slow changes in baseline. It subtracts a smoothed (1s sliding window) trace from the original data set.

            >> output_sweepset.settings.baseline_info.method='moving_average_1s';
            note: this just sets the method. Toggle baseline subtraction as above.
 
 Note that baseline subtraction can cause the sweep to 'jump' outside the current axes. Press 'Esc' to re-focus on the sweepset.

# Output data for further analysis
traces can be output for further analysis in Matlab, Graphpad prism, Excel or any other data analysis program. To output edited data type:
	
	    >> output_sweepset.output_data(‘whole_sweepset’, ‘matrix_name’);

This will output a matrix ‘matrix_name’ to the Matlab workspace. Column 1 contains the X-data (time in ms), other columns contain all selected sweeps as they are currently displayed (e.g. background subtracted or smoothed).

	    >> output_sweepset.output_data(‘average’, ‘matrix_name’);

This will output only the average trace in column 2 of matrix ‘matrix_name’, again X-data will be in column 1. The output_data method also works on the trace_combiner window. During creating the trace_combiner object was assigned to the workspace under the name ‘combiner_1’. So the following command will access the method:

	    >> combiner_1.output_data(‘matrix_name’);

This will output all selected traces to a matrix ‘matrix_name’ in the Matlab workspace. Note that 
 
 
