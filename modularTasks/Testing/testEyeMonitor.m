
clear all
clear mex
clear classes
% mexHID('initialize');
% infoStruct = mexHID('summarizeDevices');
% 
% if any([infoStruct.ProductID]==772)
%    % Josh's optical mouse
%    matching.ProductID = 772;
%    matching.PrimaryUsage = 2;
% else
%    matching = [];
% end
% 
% m = dotsReadableEyeMouseSimulator(matching);

m = dotsReadableEyePupilLabs();
m.screenEnsemble = dotsTheScreen.makeEnsemble(false, 0);
m.screenEnsemble.callObjectMethod(@open);

m.calibrate();
m.openGazeMonitor();
m.defineEvent('fpWindow', true, false, ...
         'eventName',   'holdFixation', ...
         'centerXY',    [0 0], ...
         'channelsXY',  [m.xID m.yID], ...
         'windowSize',  3);
     
for ii = 1:100
   m.read();
   pause(0.1);
end

mexHID('terminate');


