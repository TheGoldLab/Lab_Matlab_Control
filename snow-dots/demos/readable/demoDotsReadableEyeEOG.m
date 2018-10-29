
clear all
clear mex
clear classes

% Get the object
m = dotsReadableEyeEOG();
m.deviceParameters.gains = [25 25];

% Open the gaze monitor
m.openGazeMonitor();
m.defineEvent('fpWindow', true, false, ...
         'eventName',   'holdFixation', ...
         'centerXY',    [0 0], ...
         'channelsXY',  [m.xID m.yID], ...
         'windowSize',  3);

% Show it
for tt = 1:100
   m.beginTrial();
   for ii = 1:10
      pause(0.1);
      m.read();
   end
   m.endTrial();
   disp(sprintf('Trial %d', tt))
end

mexHID('terminate');