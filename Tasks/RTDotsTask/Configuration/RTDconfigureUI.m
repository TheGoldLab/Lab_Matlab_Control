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
elseif any([infoStruct.ProductID]==632)
    % use built-in keboard, new macBook Pro
    matching.ProductID = 632;
    matching.PrimaryUsage = 6;
elseif any([infoStruct.ProductID]==610)
    % use built-in keboard, old macBook Pro
    matching.ProductID = 610;
    matching.PrimaryUsage = 6;
elseif any([infoStruct.ProductID]==50475)
    matching.ProductID = 50475;
    matching.PrimaryUsage = 6;    
end

% fallback on keyboard inputs
kb = dotsReadableHIDKeyboard(matching);

% Define keypress events, undefine the rest
kb.setEventActiveFlag([], false);

% Define keypress events
kb.defineCalibratedEvent('KeyboardQ', 'quit', 1, true);
kb.defineCalibratedEvent('KeyboardP', 'pause', 1, true);
kb.defineCalibratedEvent('KeyboardD', 'done', 1, true);

% For checking
% [a,b,c,d] = kb.waitForKeyPress(kb, 'KeyboardQ',10)

% Save the keyboard
datatub{'Control'}{'keyboard'} = kb;

%% ---- Try to get pupil labs device
ui = [];
if datatub{'Input'}{'useEyeTracking'} 
    
    % Get the pupl labs eye tracking object
    pl = dotsReadableEyePupilLabs();

    % Make sure it's working
    if pl.isAvailable
        
        % Set remote info, for showing calibration on the appropriate screen
        pl.ensembleRemoteInfo = datatub{'Input'}{'remoteInfo'};
        
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
        
        % Save it
        ui = pl;
        
        % Define keypress event to trigger calibration
        kb.defineCalibratedEvent('KeyboardC', 'calibrate', 1, true);
    end
end

%% --- Otherwise use the keyboard
if isempty(ui)
    
    % Define task events
    kb.defineCalibratedEvent('KeyboardF', 'choseLeft', 1, true);
    kb.defineCalibratedEvent('KeyboardJ', 'choseRight', 2, true);
    kb.defineCalibratedEvent('KeyboardSpacebar', 'holdFixation', [], true);

    % Save it
    ui = kb;
end

% Automatically read during getNextEvent calls
ui.isAutoRead = true;

% Save the active ui device
datatub{'Control'}{'ui'} = ui;
