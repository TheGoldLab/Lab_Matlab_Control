
clear all
clear mex
clear classes

% Get the object
m = dotsReadableEyeMouseSimulator();

% Open the screen
screen = dotsTheScreen.theEnsemble(false, 0);
screen.callObjectMethod('open');

% Open the gaze monitor
m.openGazeMonitor();

% Calibrate
m.calibrate();

% show eye position
m.calibrate('s');


% Define a fixation event
% m.defineEvent('fpWindow', ...
%          'isActive',    true, ...
%          'name',        'holdFixation', ...
%          'centerXY',    [0 0], ...
%          'channelsXY',  [m.xID m.yID], ...
%          'windowSize',  3);

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