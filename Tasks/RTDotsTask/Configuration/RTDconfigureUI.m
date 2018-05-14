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
kb.defineCalibratedEvent('KeyboardC', 'done', 1, true);

% Save the keyboard
datatub{'Control'}{'keyboard'} = kb;

%ui = dotsReadableEyePupilLabs();
if false %ui.isAvailable
   
   %
   %    % set remote info, for showing calibration on the appropriate screen
   %    ui.ensembleRemoteInfo = remoteInfo;
   %
   %    % set screen width, height for calibration routine
   %    ui.windowRect = getObjectProperty(state{'graphics'}{'screenEnsemble'}, 'windowRect');
   %
   %    % calibrate
   %    ui.calibrate();
   
   %   ui.setDeviceTime
   
   %
   %    % Add gaze windows for fixation cue, two targets
   %    state{'PupilLabs'}{'fixationCueW'} = acceptibleFixationCueErrorRadius^2;
   %    state{'PupilLabs'}{'saccadeTargetErrorRad2'} = acceptibleSaccadeTargetErrorRadius^2;
   %    state{'PupilLabs'}{'stimulusErrorRad2'} = acceptibleStimulusErrorRadius^2;
   %
   %    fixationCue = state{'graphics'}{'fixationCue'};
   %    saccadeTargets = state{'graphics'}{'saccadeTargets'};
   %
   %
   %    saccadeTargets.xCenter = [-saccadeTargetoffset saccadeTargetoffset];
   %    saccadeTargets.yCenter = [0 0];
   %    saccadeTargets.nSides  = 100;
   %    saccadeTargets.height  = [1 1] * saccadeTargetSize;
   %    saccadeTargets.width   = [1 1] * saccadeTargetSize;
   %
   %
   %    % Create a fixation cue scaled by its size parameter
   %    fixationCue = dotsDrawableTargets();
   %    fixationCue.xCenter = [0 0];
   %    fixationCue.yCenter = [0 0];
   %    fixationCue.width   = [1 0.1] * fixationSize;
   %    fixationCue.height  = [0.1 1] * fixationSize;
   %    fixationCue.nSides  = 4;
   %
   %
   %    ui.addGazeWindow('fixationWindow', 'brfix', ...
   %       [fixationCue.xCenter(1) fixationCue.xCenter(2)], ...
   %
   %
   %
   %    center, ...
   %       diameter, isInverted, isActive)
   %    % These values represent the radius of acceptible error of fixation for
   %    % subjects to make for each part of the trial. Units are in degrees visual
   %    % angle.
   %    acceptibleFixationCueErrorRadius = 8;
   %    acceptibleSaccadeTargetErrorRadius = 10;
   %    acceptibleStimulusErrorRadius = 8;
   %
   %    state{'PupilLabs'}{'fixationCueErrorRad2'} = acceptibleFixationCueErrorRadius^2;
   %    state{'PupilLabs'}{'saccadeTargetErrorRad2'} = acceptibleSaccadeTargetErrorRadius^2;
   %    state{'PupilLabs'}{'stimulusErrorRad2'} = acceptibleStimulusErrorRadius^2;
   %
   %    uiMap = []; % dummy for now
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

