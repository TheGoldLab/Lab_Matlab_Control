
clear all
clear mex
clear classes

% Get the object
m = dotsReadableEyeEOG();

% Open the gaze monitor
m.openGazeMonitor();

% % Open the screen
screen = dotsTheScreen.theEnsemble(true, 1);
screen.callObjectMethod('open');
% 
% % Calibrate
m.calibrate();

% Define a fixation event
% m.defineEvent('fpWindow', true, false, ...
%          'eventName',   'holdFixation', ...
%          'centerXY',    [0 0], ...
%          'channelsXY',  [m.xID m.yID], ...
%          'windowSize',  3);

% Show it
for tt = 1:100
   m.startTrial();
   for ii = 1:100
      pause(0.01);
      m.read();
   end
   m.finishTrial();
   disp(sprintf('Trial %d', tt))
end

screen.callObjectMethod('close');
mexHID('terminate');