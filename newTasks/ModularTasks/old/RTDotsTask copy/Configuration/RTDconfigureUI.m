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

% Select appropriate keyboard by checking what is available
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
kb.deactivateEvents();

% Automatically read when checking for events
kb.isAutoRead = true;

% Define keypress events
kb.defineCalibratedEvent('KeyboardQ', 'quit', 1, true);
kb.defineCalibratedEvent('KeyboardP', 'pause', 1, true);
kb.defineCalibratedEvent('KeyboardD', 'done', 1, true);
kb.defineCalibratedEvent('KeyboardS', 'skip', 1, true);

% For checking
% [a,b,c,d] = kb.waitForKeyPress(kb, 'KeyboardQ',10)

% Save the keyboard
datatub{'Control'}{'keyboard'} = kb;

%% ---- Use named input device
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
   
   % Set up the eye position monitor
   ui.openGazeMonitor();
   
   % Set the data file to the same name as the current file, with
   % _pupilLabs suffix
   [~, name, ~] = fileparts(datatub{'Input'}{'fileName'});
   ui.filename = sprintf('%s_pupilLabs', name);
   
   % Automatically read during getNextEvent calls
   ui.isAutoRead = true;
   
   % Define gazeWindows based on fp and two targets
   % These are "compound events" that can be created all at
   % once with a cell array (mmm. celery.)
   windowSize = datatub{'Input'}{'gazeWindowSize'};
   windowDur  = datatub{'Input'}{'gazeWindowDur'};
   fpx        = datatub{'FixationCue'}{'xDVA'};
   fpy        = datatub{'FixationCue'}{'yDVA'};
   offset     = datatub{'SaccadeTarget'}{'offset'};
   
   ui.defineCompoundEvent( ...
      { 'fpWindow', ...            % Fixation window
      'eventName',   'holdFixation', ...
      'centerXY',    [fpx fpy], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur}, ...
      ...
      { 't1Window', ...            % Left target window
      'eventName',   'choseLeft', ...
      'centerXY',    [fpx-offset fpy], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur}, ...
      ...
      { 't2Window', ...            % Right target window
      'eventName',   'choseRight', ...
      'centerXY',    [fpx+offset fpy], ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur}, ...
      ...
      { 'tcWindow', ...            % General saccade target window
      'eventName',   'choseTarget', ...
      'windowSize',  windowSize, ...
      'windowDur',   windowDur});
   
   % Define keypress event to trigger calibration
   kb.defineCalibratedEvent('KeyboardC', 'calibrate', 1, true);
   
   % Add start/finish fevalables to the main topsTreeNode
   %  START calibration, recording
   addCall(datatub{'Control'}{'startCallList'}, {@calibrate, ui}, 'calibrate eye');
   addCall(datatub{'Control'}{'startCallList'}, {@record, ui, true}, 'start recording eye');
   
   %  Finish calibration, recording
   addCall(datatub{'Control'}{'finishCallList'}, {@record, ui, false}, 'finish recording eye');
   addCall(datatub{'Control'}{'finishCallList'}, {@close, ui}, 'close eye');
   
else
   %% --- Otherwise use the keyboard
   
   % Define task events
   kb.defineCalibratedEvent('KeyboardSpacebar', 'holdFixation', [], true);
   kb.defineCalibratedEvent('KeyboardF',        'choseLeft',     1, true);
   kb.defineCalibratedEvent('KeyboardJ',        'choseRight',    2, true);
   kb.defineCalibratedEvent('KeyboardT',        'choseTarget',   2, true);
   
   % Save it
   ui = kb;
end

% Save the active ui device
datatub{'Control'}{'userInputDevice'} = ui;

% Add a maintask finish fevalable to close the kb
addCall(datatub{'Control'}{'finishCallList'}, {@close, kb}, 'close keyboard');
