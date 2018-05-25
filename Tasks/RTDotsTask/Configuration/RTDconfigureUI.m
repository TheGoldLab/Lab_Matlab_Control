function RTDconfigureUI(datatub)
% function RTDconfigureUI(datatub)
%
% RTD = Response-Time Dots
%
% Configure user-interface objects:
%  1. Always puts a keyboard ui in datatub{'Control'}{'keyboard'} to check
%        for input between trials
%  2. Use either pupil labs (default) or keyboard (fallback) to get choice
%        data. Stored in datatub{'Control'}{'ui'}.
%
% 5/11/18 written by jig

%% ---- Always set up the keyboard, which can be used to abort in the ITI

% Select appropriate keyboard
mexHID('initialize');
infoStruct = mexHID('summarizeDevices');
if any([infoStruct.VendorID]==1008)
   % Josh's HP keyboard
   matching.VendorID = 1008;
   matching.ProductID = 36;
elseif any([infoStruct.ProductID]==632)
   % Josh's macBook pro built-in keboard
   matching.ProductID = 632;
   matching.PrimaryUsage = 6;
elseif any([infoStruct.ProductID]==610)
   % OR macBook pro built-in keboard
   matching.ProductID = 610;
   matching.PrimaryUsage = 6;
elseif any([infoStruct.ProductID]==50475)
   % OR mac mini wireless keyboard
   matching.ProductID = 50475;
   matching.PrimaryUsage = 6;
else
   matching = [];
end

% fallback on keyboard inputs
kb = dotsReadableHIDKeyboard(matching);

% Define keypress events, undefine the rest
kb.setEventActiveFlag([], false);

% Automatically read when checking for events
kb.isAutoRead = true;

% Define keypress events
kb.defineCalibratedEvent('KeyboardQ', 'quit', 1, true);
kb.defineCalibratedEvent('KeyboardP', 'pause', 1, true);
kb.defineCalibratedEvent('KeyboardD', 'done', 1, true);
kb.defineCalibratedEvent('KeyboardT', 'skip', 1, true);

% For checking
% [a,b,c,d] = kb.waitForKeyPress(kb, 'KeyboardQ',10)

% Save the keyboard
datatub{'Control'}{'keyboard'} = kb;

%% ---- Use named input device
ui = [];
if strcmp(datatub{'Input'}{'uiDevice'}, 'dotsReadableEyePupilLabs') || ...
      strcmp(datatub{'Input'}{'uiDevice'}, 'dotsReadableEyeMouseSimulator')
   
   % Get the pupl labs eye tracking object
   ui = eval(datatub{'Input'}{'uiDevice'});
   
   % Make sure it's working
   if ~ui.isAvailable
      ui = dotsReadableEyeMouseSimulator();
   end
   
   % Set remote info, for showing calibration on the appropriate screen
   ui.ensembleRemoteInfo = datatub{'Input'}{'remoteInfo'};
   
   % Set the data file to the same name as the current file, with
   % _pupilLabs suffix
   [~, name, ~] = fileparts(datatub{'Input'}{'fileName'});
   ui.filename = sprintf('%s_pupilLabs', name);
   
   % Automatically read during getNextEvent calls
   ui.isAutoRead = true;
   
   % Define gazeWindows based on fp and two targets
   windowSize = datatub{'Input'}{'gazeWindowSize'};
   windowDur  = datatub{'Input'}{'gazeWindowDur'};
   fpx        = datatub{'FixationCue'}{'xDVA'};
   fpy        = datatub{'FixationCue'}{'yDVA'};
   offset     = datatub{'SaccadeTarget'}{'offset'};
   
   % Fixation window
   ui.addGazeWindow('fpWindow', ...
      'eventName',   'holdFixation', ...
      'centerXY',    [fpx fpy], ...
      'channelsXY',  [ui.gXID ui.gYID], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur);
   
   % Left target window
   ui.addGazeWindow('t1Window', ...
      'eventName',   'choseLeft', ...
      'centerXY',    [fpx-offset fpy], ...
      'channelsXY',  [ui.gXID ui.gYID], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur);
   
   % Right target window
   ui.addGazeWindow('t2Window', ...
      'eventName',   'choseRight', ...
      'centerXY',    [fpx+offset fpy], ...
      'channelsXY',  [ui.gXID ui.gYID], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur);
   
   % Define keypress event to trigger calibration
   kb.defineCalibratedEvent('KeyboardC', 'calibrate', 1, true);
   
   % Add start/finish fevalables to the main topsTreeNode
   %  START calibration, recording
   addCall(datatub{'Control'}{'startCallList'}, ...
      {@calibrate, ui}, 'calibrate pupilLab');
   addCall(datatub{'Control'}{'startCallList'}, ...
      {@record, ui, true}, 'start recording pupilLab');
   
   %  Finish calibration, recording
   addCall(datatub{'Control'}{'finishCallList'}, ...
      {@record, ui, false}, 'finish recording pupilLab');
   addCall(datatub{'Control'}{'finishCallList'}, ...
      {@close, ui}, 'close pupilLab');
   
else
   %% --- Otherwise use the keyboard
   
   % Define task events
   kb.defineCalibratedEvent('KeyboardF', 'choseLeft', 1, true);
   kb.defineCalibratedEvent('KeyboardJ', 'choseRight', 2, true);
   kb.defineCalibratedEvent('KeyboardSpacebar', 'holdFixation', [], true);
   
   % Save it
   ui = kb;
end

% Save the active ui device
datatub{'Control'}{'ui'} = ui;

% Add a maintask finish fevalable to close the kb
addCall(datatub{'Control'}{'finishCallList'}, ...
   {@close, kb}, 'close keyboard');
