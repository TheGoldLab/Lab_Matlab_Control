
clear all
clear mex
clear classes

% Get the object
m = dotsReadableEyeMouseSimulator();

% Open the gaze monitor
m.openGazeMonitor();

% Open the screen
screen = dotsTheScreen.makeEnsemble(false, 0);
screen.callObjectMethod('open');

% Calibrate
m.calibrate();

% Define a fixation event
m.defineEvent('fpWindow', ...
         'isActive',    true, ...
         'name',        'holdFixation', ...
         'centerXY',    [0 0], ...
         'channelsXY',  [m.xID m.yID], ...
         'windowSize',  3);

% Show output
for tt = 1:100
   m.startTrial();
   for ii = 1:10
      pause(0.1);
      m.read();
   end
   m.finishTrial();
   disp(sprintf('Trial %d', tt))
end

screen.callObjectMethod('close');
mexHID('terminate');