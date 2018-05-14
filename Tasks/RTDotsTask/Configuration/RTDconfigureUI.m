function RTDconfigureUI(datatub)
% function RTDconfigureUI(datatub)
%
% RTD = Response-Time Dots
%
% Configure user-interface objects:
%  1. Pupil labs
%  2. keyboard (fallback)
%
% 5/11/18 written by jig

%% ---- Always set up the keyboard, which can be used to abort in the ITI

% Select appropriate keyboard
mexHID('initialize');
infoStruct = mexHID('summarizeDevices');
if any([infoStruct.VendorID]==1008)
   % use attached keboard
   matching.VendorID = 1008;
   matching.ProductID = 36;
else
   % use built-in keboard
   matching.ProductID = 632;
   matching.PrimaryUsage = 6;
end

% fallback on keyboard inputs
kb = dotsReadableHIDKeyboard(matching);

% Define keypress events, undefine the rest
kb.setEventActiveFlag([], false);

% Automatically read during getNextEvent calls
kb.isAutoRead = true;

% Define keypress events
kb.defineCalibratedEvent('KeyboardQ', 'quit', 1, true);
kb.defineCalibratedEvent('KeyboardP', 'pause', 1, true);
kb.defineCalibratedEvent('KeyboardD', 'done', 1, true);

% Save the keyboard
datatub{'Control'}{'keyboard'} = kb;

%% ---- Try to get pupil labs device
pl = dotsReadableEyePupilLabs();
if pl.isAvailable
   
   % Set remote info, for showing calibration on the appropriate screen
   pl.ensembleRemoteInfo = remoteInfo;
   
   % Set screen width, height for calibration routine
   pl.windowRect = getObjectProperty( ...
      datatub{'graphics'}{'screenEnsemble'}, 'windowRect');
   
   % Calibrate
   pl.calibrate();
   
   % Define gazeWindows based on fp and two targets
   windowSize = datatub{'Input'}{'gazeWindowSize'};
   windowDur  = datatub{'Input'}{'gazeWindowDur'};
   fpx        = datatub{'FixationCue'}{'xDVA'};
   fpy        = datatub{'FixationCue'}{'yDVA'};
   offset     = datatub{'SaccadeTarget'}{'offset'};
   
   % Fixation window
   pl.addGazeWindow('fpWindow', ...
      'eventName',   'holdFixation', ...
      'centerXY',    [fpx fpy], ...
      'channelsXY',  [pl.gXID pl.gYID], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur);
   
   % Left target window
   pl.addGazeWindow('t1Window', ...
      'eventName',   'choseLeft', ...
      'centerXY',    [fpx-offset fpy], ...
      'channelsXY',  [pl.gXID pl.gYID], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur);
   
   % Right target window
   pl.addGazeWindow('t2Window', ...
      'eventName',   'choseRight', ...
      'centerXY',    [fpx+offset fpy], ...
      'channelsXY',  [pl.gXID pl.gYID], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur);
   
   % Define keypress event to trigger calibration
   kb.defineCalibratedEvent('KeyboardC', 'calibrate', 1, true);

else
   
   % Otherwise use the keyboard
   
   % Define task events
   kb.defineCalibratedEvent('KeyboardF', 'choseLeft', 1, true);
   kb.defineCalibratedEvent('KeyboardJ', 'choseRight', 2, true);
   kb.defineCalibratedEvent('KeyboardSpacebar', 'holdFixation', [], true);
   ui = kb;
end

% Save the active ui device
datatub{'Control'}{'ui'} = ui;

%datatub{'input'}{'mapping'} = uiMap;

% 
% % make a call list so this can be added to a concurrentComposite
% uiCallList = topsCallList('read ui');
% uiCallList.addCall({@read, ui}, 'read input');
% datatub{'Control'}{'uiCallList'} = uiCallList;

