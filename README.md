# Ex-vivo-ephys-toolset
A series of Matlab scripts to import analyze slice electrophysiology recordings collected with Pclamp (Molecular Devices).

The toolset is based on 'abfload.m', which imports .abf files into matlab arrays. Abfload was made by Harald Hentschke.

Instalation:
Make sure the following files are avialble on the Matlab path:
abfload.m                                    - For import of .abf files. Made by Harald Hentschke.
pvpmod.m                                     - Deals with varargin in abfload.m. Made by Ulrich Egert
sweepset.m                                   - Describes the sweepset class. Made by Han de Jong
measure.m & measure.fig                      - GUI for amplitude measurements of events
firing_frequency.m & firing_frequency.fig    - GUI for measuring frequency of events
Bearphys.m & Bearphys.fig                    - GUI for interaction with sweepset.m.


How to get started:
The basis of the toolkit is the sweepset object into which .abf recordings are loaded. A sweepset class is initiated by the command:
      
            >> output_sweepset=sweepset('user_select','on')

This will create a sweepset object named 'output_sweepset'. The first sweep is presented in a figure and data about the dataset is printed to the command line. The following comand prints information about the sweepset (such as the sampling frequency):

            >> output_sweepset.file_header

If the window that displays the sweepset is active. One can scroll through the different sweeps using the arrow keys. Alternatively the following keypresses are currently supported:

          arrow keys left and right:  Scroll trough different sweeps
          Q:                          Substract baseline (see baseline method below)
          A:                          Display average sweep (uses only 'selected', not 'rejected' sweeps)
          Z:                          Display entire dataset in background
          S:                          Select sweeps (sweeps are selected by default).
          R:                          Reject sweep (meaning that the sweep will not be taken in to account in any analysis)
          ENTER:                      Print the current sweep selectino to the commmand line
          M:                          Open measurement GUI for measurement of amplitude of peaks.
          F:                          Open GUI for measuring event frequency
