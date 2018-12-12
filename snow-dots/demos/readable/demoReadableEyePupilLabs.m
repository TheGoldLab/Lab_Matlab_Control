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

%% Open the gaze monitor
%
% This opens a window that shows eye position and gaze events
pl.openGazeMonitor();

% Calibration requires a SnowDots screen to be open. Open a small debug 
%  window in local mode
% For remote mode, primary screen:
% screen = dotsTheScreen.makeEnsemble(true, 1);
screen = dotsTheScreen.makeEnsemble(false, 0);
screen.callObjectMethod('open');

% Run the calibration routine
pl.calibrate();

% Run the "show eye" routine ... end by pressing the spacebar
pl.calibrate('s')

% Show output on the eye monitor
for tt = 1:100
   for ii = 1:10
      pause(0.1);
      pl.read();
   end
   disp(sprintf('Trial %d', tt))
end

% Close the window
screen.callObjectMethod('close');
