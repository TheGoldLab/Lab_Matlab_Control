%% demoReadableEyePupilLabs
%
% This script demonstrates the basic usage of the dotsReadableEyePupilLabs
% class. We will run the calibration scripts using the readable object and
% then record data. This script will demonstrate how the object keeps an
% internal recording of the data as well as how to get the results as a
% function output. Additionally, some methods to interface with PupilLabs
% will also be demonstrated.

%% Initialize the class
pl = dotsReadableEyePupilLabs;

%% Run calibrations
%
% Both calibrations require a SnowDots screen to be open. We will first
% open a screen and then run the two calibration routines.
s = dotsTheScreen.theObject;
s.displayIndex = 1;
s.openWindow;

% Pause briefly to allow the window to load. We then run the pupil labs
% calibration (which needs to know the screen size). Then we run the
% SnowDots calibration. Note that the graphics for both can be run on a
% remote machine by providing client and server IP/port inputs.
pause(1);
pl.calibratePupilLab(s);
pl.calibrateSnowDots;

pause(1);
s.closeWindow;

%% Read data
%
% There are two ways to read data using the dotsReadableEyePupilLabs class.
% The first is using the 'read()' method which behaves like it does in any
% of the other dotsReadable classes. It records the data read in the
% 'history' variable inside the class. The second way is to use the
% 'readAndReturnData()' method which directly output the data and not save
% it in the 'history' variable.

% Using the 'read()' method allows you to take advantage of the event
% detection implementation in the dotsReadable class. The 'flushData()'
% method clears the history variable.
pl.read();
pl.history
pl.flushData();

% Using the 'readAndReturnData()' class allows direct access to the data,
% but does not use the event detection implementations in the dotsReadable
% class.
pl.readAndReturnData()

% Because the PupilLabs data stream is implemented as a TCP connection, if
% you do not read the data out fast enough, packets will pile up and you
% will not receive temporally synced data. To get around this,
% occassionally use the 'refreshSocket()' function which clears the piled
% up packets by disconnecting and reconnecting the socket. However, be
% careful of using this function too frequently as sockets are not released
% immediately (can take a few seconds).
d = pl.readAndReturnData();
fprintf('Data packet timestamp :%0.6f\n',d(1,3));

pause(5);
d = pl.readAndReturnData();
fprintf('Data packet timestamp :%0.6f\n',d(1,3));
pl.refreshSocket();
d = pl.readAndReturnData();
fprintf('Data packet timestamp :%0.6f\n',d(1,3));

%% Other functions
%
% There are two other useful utility functions available in the
% dotsReadableEyePupilLabs class. These functions allow you to get the
% current time on the PupilLabs software as well as reset the time to an
% arbitrary value.

% This will set the timer on the PupilLabs software to 0 (or whatever value
% you wish) and have it start counting from there.
pl.timeSync(0);

% This retrieves the current time value on the PupilLabs software.
disp(pl.getTime())