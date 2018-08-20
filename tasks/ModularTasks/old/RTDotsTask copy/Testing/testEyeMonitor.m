
clear all
clear mex
clear classes
mexHID('initialize');
infoStruct = mexHID('summarizeDevices');

if any([infoStruct.ProductID]==772)
   % Josh's optical mouse
   matching.ProductID = 772;
   matching.PrimaryUsage = 2;
else
   matching = [];
end

m = dotsReadableEyeMouseSimulator(matching);

m.showGazeMonitor = true;
m.addGazeWindow('fpWindow', ...
         'eventName',   'holdFixation', ...
         'centerXY',    [0 0], ...
         'channelsXY',  [m.xID m.yID], ...
         'windowSize',  3, ...
         'isActive',    true);


for ii = 1:100
   m.read();
   pause(0.1);
end

mexHID('terminate');


