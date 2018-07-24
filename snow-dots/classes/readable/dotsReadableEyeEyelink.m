classdef dotsReadableEyeEyelink < dotsReadableEye
    % @class dotsReadableEyeEyelink
    % Reads Eyelink gaze and pupil size data.
    % @details
    % dotsReadableEyeEyelink extends the dotsReadableEye superclass to
    % acquire point of gaze and pupil size data from an Eyelink eye
    % tracker.
    % @details
    % It relies on mglEyelink functions which are part of the mgl project.
    
    properties
        
        % IP address of the Eyelink machine
        eyelinkIP = '100.1.1.1';
        
        % Time for eyelink to switch to new mode (msec)
        waitForModeReadyTime = 50;
        
        % Whether or not to automatically do validation after calibration
        validateAfterCalibration = true;
        
        % calibration/validation pacing: 0 (for manual trigger) or
        %  500, 1000, or 1500 (msec)
        defaultPacing = 0;
        
        % do calibration step during calibration
        doCalibration = true;
        
        % do validation step during calibration
        doValidation = true;
        
        % Frequency/duration/intensity values for calibration feedback tones
        calibrationTargetBeep  = [1250 0.05 0.6];
        calibrationSuccessBeep = [ 400 0.25 0.8];
        calibrationFailureBeep = [ 800 0.25 0.8];
        
    end % Public properties
    
    properties (SetAccess = protected)
        
        % Which eye are we tracking?
        trackedEye = [];
        
        % Playable objects for calibration feedback tones
        calibrationPlayables = {};
        
        % Center of window rect for converting screen coordinates into deg vis ang
        windowCtr = [];
        
        % Pixels per degree for converting screen coordinates into deg vis ang
        pixelsPerDegree = [];
        
        % Return values from Eyelink
        NO_REPLY=1000;              % no reply yet (for polling test)
        KB_PRESS=10;                % pressed keyboard
        MISSING=-32768;             % eyedata.h
        IN_DISCONNECT_MODE=16384;   % disconnected
        IN_UNKNOWN_MODE=0;    		% mode fits no class (i.e setup menu)
        IN_IDLE_MODE=1;    			% off-line
        IN_SETUP_MODE=2;   			% setup or cal/val/dcorr
        IN_RECORD_MODE=4;           % data flowing
        IN_TARGET_MODE=8;           % some mode that needs fixation targets
        IN_DRIFTCORR_MODE=16;       % drift correction
        IN_IMAGE_MODE=32;   			% image-display mode
        IN_USER_MENU=64;				% user menu
        IN_PLAYBACK_MODE=256;       % tracker sending playback data
        
    end % Protected properties
    
    methods
        % Constructor takes no arguments.
        function self = dotsReadableEyeEyelink()
            self = self@dotsReadableEye();
            self.initialize();
        end
        
        % Get the current time value from Eyelink. Units are in seconds.
        function time = getDeviceTime(self)
            
            if self.isAvailable
                time = Eyelink('TrackerTime');
            else
                time = feval(self.clockFunction);
            end
        end
        
        % Transfer data file
        function transferDataFile(self, pathname)
            
            % get the file
            status = Eyelink('ReceiveFile', [], [], pathname);
            if status == 0
                warning('Eyelink ReceiveFile error');
            end
        end
        
    end % Public methods
    
    methods (Access = protected)
        
        % Acquire Eyelink resources.
        function isOpen = openDevice(self)
            
            % release stale resources
            self.closeDevice();
            
            try
                
                % Set IP
                Eyelink('SetAddress', self.eyelinkIP);
                
                % Returns 0 if ok
                isOpen = ~Eyelink('Initialize', []);
                
                % make sure that we get gaze, pupil data from the Eyelink
                % Also possibly:HREF
                if isOpen
                    Eyelink('Command', 'link_sample_data = GAZE,AREA');
                    Eyelink('Command', 'pupil_size_diameter = YES');
                end
                
            catch err
                warning(err.message);
            end
        end % openDevice
        
        % Release Eyelink resources.
        function closeDevice(self)
            
            % Stop eye recording
            if Eyelink('IsConnected') && ~Eyelink('CheckRecording')
                Eyelink('StopRecording');
            end
            
            % shutdown connection
            if self.isAvailable
                Eyelink('Shutdown');
            end
            
        end % closeDevice
        
        % Calibrate the eye tracker
        %
        % Returns status: 0 for error, 1 for good calibration
        function status = calibrateNow(self)
            
            % default return
            status = 0;
            
            % Check for connection
            if ~Eyelink('IsConnected')
                disp('EYELINK NOT CONNECTED')
                status = -1;
                return
            end
            
            % Turn off recording during calibration
            if Eyelink('CheckRecording') == 0
                Eyelink('StopRecording');
            end
            
            % Setup calibration graphics
            %
            if isempty(self.pixelsPerDegree)
                
                % Set screen coordinates
                windowRect = getObjectProperty(self.screenEnsemble, 'windowRect');
                Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', ...
                    windowRect(1), windowRect(2), windowRect(3)-1, windowRect(4)-1);
                self.pixelsPerDegree = getObjectProperty(self.screenEnsemble, 'pixelsPerDegree');
                self.windowCtr = [windowRect(3)/2 windowRect(4)/2];
            end
            
            % Create feedback sounds
            %
            if isempty(self.calibrationPlayables)
                self.calibrationPlayables = { ...
                    dotsPlayableTone.makePlayableTone(self.calibrationTargetBeep), ...
                    dotsPlayableTone.makePlayableTone(self.calibrationSuccessBeep), ...
                    dotsPlayableTone.makePlayableTone(self.calibrationFailureBeep)};
            end
            
            % Put Eyelink in setup mode and wait for mode change
            %
            Eyelink('StartSetup');
            Eyelink('WaitForModeReady', self.waitForModeReadyTime);
            pause(0.15);
            
            % Blank screen (black background)
            self.calibrationEnsemble.callObjectMethod(...
                @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
            
            % Flush the ui
            self.calibrationUI.flushData();
            
            % Possibly toggle pacing
            pacingVals = [0 500 1000 1500];
            pacingI = find(self.defaultPacing==pacingVals,1);
            isCalibrated = false;
            
            while ~isCalibrated
                
                % Possibly query for input
                if self.queryDuringCalibration
                    
                    % flush keyboard
                    while ~isempty(self.calibrationUI.getNextEvent()) end
                    self.calibrationUI.flushData();
                    
                    % Show instructions
                    stars = cell(4,1);
                    stars{pacingI} = '*';
                    disp('space to continue, q to quit');
                    disp(sprintf( ...
                        't to toggle acceptance pacing [manual%s 500%s 1000%s 1500%s]', ...
                        stars{1}, stars{2}, stars{3}, stars{4}))
                    disp(' ')
                    
                    % Wait for keyboard input
                    [didHappen, ~, ~, ~, nextEvent] = dotsReadable.waitForEvent( ...
                        self.calibrationUI, [], self.queryTimeout);
                    
                    % Made it through timeout, just continue. Otherwise
                    % wait for key up
                    if ~didHappen
                        nextEvent = 'accept';
                    else
                        dotsReadable.waitForEvent(self.calibrationUI, [], self.queryTimeout);
                    end
                    
                else
                    nextEvent = 'accept';
                end
                
                % Parse input
                switch nextEvent
                    
                    case {'accept', 'calibrate'}
                        
                        % setup calibration parameters
                        Eyelink('Command', 'calibration_type = HV9');
                        Eyelink('Command', sprintf('automatic_calibration_pacing = %d', pacingVals(pacingI)));
                        if pacingVals(pacingI)==0
                            Eyelink('Command', 'enable_automatic_calibration = NO');
                        else
                            Eyelink('Command', 'enable_automatic_calibration = YES');
                        end
                        pause(0.25);
                        status = self.calibrateValidate('c', pacingVals(pacingI)>0);
                        isCalibrated = true;
                        
                    case 'abort'
                        isCalibrated = true;
                        
                    case 'toggle'
                        pacingI = pacingI + 1;
                        if pacingI > length(pacingVals)
                            pacingI = 1;
                        end
                end
            end
            
            % Get eye that's tracked... use LEFT if both
            % EyeAvailable returns: 0=Left, 1=Right, 2=Binocular
            % convert to 1=Left, 2=Right
            self.trackedEye = Eyelink('EyeAvailable')+1;
            if self.trackedEye == 3
                self.trackedEye = 1; % use left if binocular
            end
            
            % Turn on recording
            Eyelink('StartRecording');
            pause(0.2);
        end
        
        % calibrateValidate
        %
        % Perform calibration or validation procedure
        function status = calibrateValidate(self, mode, autoTrigger)
            
            % Default outcome (no error)
            status = 0;
            
            % count targets to make sure we cycle through all of them
            % before finishing
            count = 0;
            
            % Set mode
            Eyelink('SendKeyButton', double(mode), 0, self.KB_PRESS);
            pause(0.2);
            if autoTrigger
                Eyelink('SendKeyButton', double('A'), 0, self.KB_PRESS);
            end
            
            % Loop through the protocol
            targetOldX           = self.MISSING;
            targetOldY           = self.MISSING;
            continueCalibration  = true;
            while continueCalibration
                
                % Check for target show/move
                [targetCheck, targetX, targetY] = Eyelink('TargetCheck');
                pause(0.2);
                
                [result, ~] = Eyelink('CalMessage');
                %                 if result ~= 0 || ~isempty(messageString)
                %                     disp([-88 result])
                %                     disp(messageString)
                %                 end
                
                % Get Eyelink mode
                currentMode = Eyelink('CurrentMode');
                
                % Check for end of calibrate/validate or no more setup/target mode
                if count >= 10 && ((targetCheck==0 && result~=0) || ...
                        ~bitand(currentMode, self.IN_SETUP_MODE) || ...
                        ~bitand(currentMode, self.IN_TARGET_MODE))
                    if mode == 'c'
                        % Eyelink('SendKeyButton', 88, 0, self.KB_PRESS)
                        pause(0.5)
                        calibrateValidate(self, 'v', autoTrigger);
                        return;
                    else
                        pause(0.2);
                        Eyelink('SendKeyButton', 13, 0, self.KB_PRESS);
                        pause(0.2);
                        break;
                    end
                end
                
                % Check to erase or (re)draw the target
                if targetCheck==0 || targetX == self.MISSING || ...
                        targetY == self.MISSING
                    
                    % Blank the screen
                    self.calibrationEnsemble.callObjectMethod(...
                        @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
                    
                    % Indicate not drawn
                    targetOldX = self.MISSING;
                    targetOldY = self.MISSING;
                    waitingForAcceptance = false;
                    
                elseif targetCheck==1
                    
                    % checking for trigger
                    waitingForAcceptance = true; % aren't we all?
                    
                    % check for redraw
                    if targetX ~= targetOldX || targetY ~= targetOldY
                        
                        % Present calibration target at the updated position,
                        % converted into degrees visual angle wrt center of
                        % screen
                        self.calibrationEnsemble.setObjectProperty('xCenter', ...
                            (targetX - self.windowCtr(1))/self.pixelsPerDegree);
                        self.calibrationEnsemble.setObjectProperty('yCenter', ...
                            -(targetY - self.windowCtr(2))/self.pixelsPerDegree);
                        
                        % blank/pause/draw+flip/woo hoo!
                        if count==1
                            pause(0.2);
                        end
                        self.calibrationEnsemble.callObjectMethod(...
                            @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
                        pause(0.2);
                        self.calibrationEnsemble.callObjectMethod(...
                            @dotsDrawable.drawFrame, {}, [], true);
                        
                        % update the count
                        count = count + 1;
                        % disp(count)
                        
                        % Set flags
                        targetOldX = targetX;
                        targetOldY = targetY;
                        
                        % Play alerting sound
                        play(self.calibrationPlayables{1});
                    end
                end
                
                % Get user input
                switch self.calibrationUI.getNextEvent()
                    
                    case 'accept'
                        
                        % Aceept current calibration target
                        if waitingForAcceptance
                            % Eyelink('SendKeyButton', 32, 0, self.KB_PRESS);
                            Eyelink('AcceptTrigger');
                            waitingForAcceptance = false;
                        end
                        
                        % Wait to release keypress
                        while ~isempty(self.calibrationUI.getNextEvent()) end
                        self.calibrationUI.flushData();
                        
                    case 'abort'
                        
                        % Abort the process.
                        status = 1;
                        break;
                end
            end % while continueCalibration
            
            % Blank the screen
            self.calibrationEnsemble.callObjectMethod(...
                @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
        end
        
        % Drift correction
        %
        %  Optional arguments are:
        %     xy         ... [x,y] referent location
        %     drawTarget ... flag to draw target at xy
        %
        function status = driftCorrect(self, xy, drawTarget)
            
            % Send mode key
            Eyelink('SendKeyButton', double('d'), 0, self.KB_PRESS);
            
            % Check args
            if nargin < 1 || isempty(xy)
                xy = [0 0];
            end
            
            if nargin < 2 || isempty(drawTarget)
                drawTarget = false;
            end
            
            % Not sure why we need to do this
            Eyelink('Command', 'heuristic_filter = ON');
            
            % Possibly draw the target
            if drawTarget
                
                % Present calibration target at the updated position
                self.calibrationEnsemble.setObjectProperty('xCenter', xy(1));
                self.calibrationEnsemble.setObjectProperty('yCenter', xy(2));
                
                % Draw the target and flip the buffer
                self.calibrationEnsemble.callObjectMethod(...
                    @dotsDrawable.drawFrame, {}, [], true);
                
                % Play alerting sound
                play(self.calibrationPlayables{1});
            end
            
            % Start drift correction routine
            Eyelink('DriftCorrStart', ...
                self.windowCtr(1) + xy(1) * self.pixelsPerDegree, ...
                self.windowCtr(2) - xy(2) * self.pixelsPerDegree);
            
            % Wait for confirmation.
            while Eyelink('CalResult') == self.NO_REPLY
                
                % Get user input
                switch self.calibrationUI.getNextEvent()
                    
                    case 'acceptCalibration'
                        
                        % Accept the trigger and apply the drift correction
                        Eyelink('AcceptTrigger');
                        Eyelink('ApplyDriftCorr');
                        status = 0;
                        
                    case 'abortCalibration'
                        status = 0; % no error (for now)
                        break;
                        % Possibly return to setup menu?
                        % Eyelink('StartSetup');
                        % Eyelink('WaitForModeReady', self.waitForModeReadyTime);
                end
            end
            
            % Blank the screen if we drew the target
            if drawTarget
                self.calibrationEnsemble.callObjectMethod(...
                    @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
            end
        end % drift correct
        
        % Overloaded startRecording method
        %
        function isRecording = startRecording(self)
            
            % Check for filename
            if isempty(self.filename)
                
                % Use default filename
                self.filename = 'tmpEyeFile';
            end
            
            % Open data file
            isRecording = ~Eyelink('OpenFile', self.filename);
        end % startRecording
        
        % Overloaded stopRecording method
        %
        function isRecording = stopRecording(self)
            
            % Close data file
            isRecording = ~Eyelink('CloseFile');
            
        end % stopRecording
        
        % Read raw Eyelink data.
        %
        % Reads out the current data sample from Eyelink, for on-line checking.
        %  NOTE: possibly update to read buffered data, if we end up missing
        %  samples. Otherwise, it might not be worth it to get all the
        %  buffered data -- here we are just typically checking for task flow
        %  control, note that the full data set is stored on the eyelink
        %  computer.
        %
        % New samples are converted to the dotsReadable three-column style as:
        %   - [xID, x, timestamp]
        %   - [yID, y, timestamp]
        %   - [pupilID, pupilSize, timestamp]
        %
        % where timestamp is pulled from the new sample and is from the
        %   eyelink clock.
        function newData = readRawEyeData(self)
            
            if ~self.isAvailable || Eyelink('NewFloatSampleAvailable') <= 0
                newData = zeros(0, 3);
                return
            end
            
            % get the sample in the form of an event structure
            evt = Eyelink('NewestFloatSample');
            
            % Convert to degrees visual angle wrt center of the screen
            x =  (evt.gx(self.trackedEye) - self.windowCtr(1))/self.pixelsPerDegree;
            y = -(evt.gy(self.trackedEye) - self.windowCtr(2))/self.pixelsPerDegree;
            
            % package up data in dotsReadable format
            newData = [ ...
                self.xID      x                       evt.time; ...
                self.yID      y                       evt.time; ...
                self.pupilID  evt.pa(self.trackedEye) evt.time];
            
        end % readRawEyeData
    end % Protected methods
end