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
      waitForModeReadyTime = 500;
      
      % Frequency/duration/intensity values for calibration feedback tones
      calibrationTargetBeep  = [1250 0.05 0.6];
      calibrationSuccessBeep = [ 400 0.25 0.8];
      calibrationFailureBeep = [ 800 0.25 0.8];
      
      % Calibration user-input device type. For now restricted to:
      %     'dotsReadableHIDKeyboard'
      %     'dotsReadableHIDGamepad'
      calibrationUIType = 'dotsReadableHIDKeyboard';
      
      % Keyboard event definitions: type, key/event pairs
      % jig TODO GAMEPAD
      calibrationUIEvents = { ...
         'dotsReadableHIDKeyboard', ...
         {'KeyboardSpacebar', 'acceptCalibration'; ...
         'keyboardQ', 'abortCalibration'}; ...
         'dotsReadableHIDGamepad', ...
         {'GamepadB', 'acceptCalibration'; ...
         'GamepadA', 'abortCalibration'}};
      
   end % Public properties
   
   properties (SetAccess = protected)
      
      % Which eye are we tracking?
      trackedEye = [];
      
      % Playable objects for calibration feedback tones
      calibrationPlayables = {};
      
      % Calibration user input
      calibrationUI = [];
      
      % Return values from Eyelink
      NO_REPLY=1000;             % no reply yet (for polling test)
      KB_PRESS=10;               % pressed keyboard
      MISSING=-32768;            % eyedata.h
      IN_DISCONNECT_MODE=16384;  % disconnected
      IN_UNKNOWN_MODE=0;    		% mode fits no class (i.e setup menu)
      IN_IDLE_MODE=1;    			% off-line
      IN_SETUP_MODE=2;   			% setup or cal/val/dcorr
      IN_RECORD_MODE=4;    		% data flowing
      IN_TARGET_MODE=8;    		% some mode that needs fixation targets
      IN_DRIFTCORR_MODE=16;      % drift correction
      IN_IMAGE_MODE=32;   			% image-display mode
      IN_USER_MENU=64;				% user menu
      IN_PLAYBACK_MODE=256;		% tracker sending playback data
      
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
            if isOpen
               Eyelink('Command', 'link_sample_data = GAZE,AREA');
            end
            
         catch err
            warning(err.message);
         end
      end % openDevice
      
      % Release Eyelink resources.
      function closeDevice(self)
         
         if self.isAvailable
            Eyelink('Shutdown');
         end
         
      end % closeDevice
      
      % Calibrate the eye tracker
      %
      % Optional argument is char indicating mode:
      %  'c'      ... calibrate
      %  'v'      ... validate
      %  'e'      ... show eye position
      %  'd'      ... drift correct
      %
      % Returns status: 0 for error, 1 for good calibration
      function status = calibrateDevice(self, mode, varargin)
         
         % Check for connection
         if ~Eyelink('IsConnected')
            status = 0;
            return
         end
         
         % Setup calibration graphics
         %
         if isempty(self.calibrationEnsemble)
            
            % Set screen coordinates
            windowRect = getObjectProperty(self.screenEnsemble, 'windowRect')
            Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', ...
               windowRect(1), windowRect(2), windowRect(3)-1, windowRect(4)-1);
            
            % Create a single drawable object to represent the fixation cue.
            % Then, we simply adjust the location of the cue each time we present it.
            fixationCue = dotsDrawableTargets();
            fixationCue.width  = [1 0.1] * self.calibrationFPSize;
            fixationCue.height = [0.1 1] * self.calibrationFPSize;
            self.calibrationEnsemble = makeDrawableEnsemble(...
               'calibrationEnsemble', {fixationCue}, self.screenEnsemble);
         end
         
         % Create feedback sounds
         %
         if isempty(self.calibrationPlayables)
            self.calibrationPlayables = { ...
               dotsPlayableTone.makePlayableTone(self.calibrationTargetBeep), ...
               dotsPlayableTone.makePlayableTone(self.calibrationSuccessBeep), ...
               dotsPlayableTone.makePlayableTone(self.calibrationFailureBeep)};
         end
         
         % Set up user input
         %
         if isempty(self.calibrationUI);
            
            % Make the ui object
            self.calibrationUI = feval(self.calibrationUIType);
            
            % Deactivate all events
            self.calibrationUI.deactivateEvents();
            
            % Get the event definitions
            eventIndex = find(strcmp(self.calibrationUIType, ...
               self.calibrationUIEvents(:,1)));
            
            % Now add given events. Note that the third and fourth arguments
            %  to defineCalibratedEvent are Calibrated value and isActive --
            %  we could make those user controlled.
            for ii = 1:size(self.calibrationUIEvents{eventIndex,2})
               self.calibrationUI.defineCalibratedEvent( ...
                  self.calibrationUIEvents{eventIndex,2}{1}, ...
                  self.calibrationUIEvents{eventIndex,2}{2}, ...
                  1, true);
            end
         end
         
         % Put Eyelink in setup mode and wait for mode change
         %
         Eyelink('StartSetup');
         Eyelink('WaitForModeReady', self.waitForModeReadyTime);
         
         % Blank screen (black background)
         self.calibrationEnsemble.callObjectMethod(...
            @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
         
         % Mode
         if nargin < 2 || isempty(mode)
            mode = 'c';
         end
         
         switch mode
            
            case {'d' 'D'}
               % Takes optional arguments
               status = self.driftCorrectNow(varargin{:});
               
            case {'e' 'E'}
               status = self.showEyeNow();
               
            case {'v' 'V'}
               status = self.validateNow();
               
            otherwise % case {'c' 'C'}
               status = self.calibrateNow();
         end
      end
      
      % Calibration routine
      %
      function status = calibrateNow(self)
         
         % Send mode key
         Eyelink('SendKeyButton', double('c'), 0, self.KB_PRESS);
         
         % Loop through the calibration protocol
         targetOldX           = self.MISSING;
         targetOldY           = self.MISSING;
         waitingForAcceptance = false;
         continueCalibration  = true;
         while continueCalibration
            
            % Get Eyelink mode
            currentMode = Eyelink('CurrentMode');
            
            % Check for setup/target mode
            if bitand(currentMode, self.IN_SETUP_MODE) && ...
                  bitand(currentMode, self.IN_TARGET_MODE)
               
               % Check for target show/move
               [targetCheck, targetX, targetY] = Eyelink('TargetCheck');
               
               % Check to erase or (re)draw the target
               if (targetCheck==0 || targetX == self.MISSING || ...
                     targetY == self.MISSING) && (targetOldX ~= self.MISSING || ...
                     targetOldY ~= self.MISSING)
                  
                  % Blank the screen
                  self.calibrationEnsemble.callObjectMethod(...
                     @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
                  
                  % Indicate not drawn
                  targetOldX = self.MISSING;
                  targetOldY = self.MISSING;
                  
               elseif (targetCheck==1 && targetX ~= self.MISSING && ...
                     targetY ~= self.MISSING) && (targetX ~= targetOldX || ...
                     targetY ~= targetOldY)
                  
                  % Present calibration target at the updated position
                  self.calibrationEnsemble.setObjectProperty('xCenter', targetX);
                  self.calibrationEnsemble.setObjectProperty('yCenter', targetY);
                  
                  % Draw the target and flip the buffer
                  self.calibrationEnsemble.callObjectMethod(...
                     @dotsDrawable.drawFrame, {}, [], true);
                  
                  % Set flags
                  targetOldX = targetX;
                  targetOldY = targetY;
                  waitingForAcceptance = true; % aren't we all?
                  
                  % Play alerting sound
                  play(self.calibrationPlayables{1});
               end
               
               % Get user input
               switch self.calibrationUI.getNextEvent()
                  
                  case 'acceptCalibration'
                     
                     % Aceept current calibration target
                     if waitingForAcceptance
                        Eyelink('AcceptTrigger');
                        waitingForAcceptance = false;
                     end
                     
                  case 'abortCalibration'
                     
                     % Abort the process.
                     continueCalibration = false;
               end
               
            else % no longer in setup/target mode
               continueCalibration = false;
            end
         end % while continueCalibration
         
         % Blank the screen
         self.calibrationEnsemble.callObjectMethod(...
            @dotsDrawable.blankScreen, {[0 0 0]}, [], true);
         
         % Check for success and play appropriate sound
         if Eyelink('CalResult')==1
            
            % Success!!            
            play(self.calibrationPlayables{1}); 
            status = 0;
         else
            
            % Failure!!
            play(self.calibrationPlayables{2}); 
            status = 1;
         end
         
         % Get eye that's tracked... use LEFT if both
         % EyeAvailable returns: 0=Left, 1=Right, 2=Binocular
         % convert to 1=Left, 2=Right
         self.trackedEye = Eyelink('EyeAvailable')+1;
         if self.trackedEye == 3
            self.trackedEye = 1; % use left if binocular
         end
      end
      
      % Drift correction
      %
      %  Optional arguments are:
      %     xy         ... [x,y] referent location
      %     drawTarget ... flag to draw target at xy
      %
      function status = driftCorrectNow(self, xy, drawTarget)
         
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
         Eyelink('DriftCorrStart', xy(1), xy(2));
         
         waitingForAcceptance = self.NO_REPLY;
         while waitingForAcceptance == self.NO_REPLY
            
            % check for result of drift correction
            waitingForAcceptance = Eyelink('CalResult');
            
            % Get user input
            switch self.calibrationUI.getNextEvent()
               
               case 'acceptCalibration'
                  
                  % Accept the trigger and apply the drift correction
                  Eyelink('AcceptTrigger');
                  Eyelink('ApplyDriftCorr');
                  status = 0;
                  
               case 'abortCalibration'
                  waitingForAcceptance = -1;
                  status = 0; % no error (for now)
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
      
      % Show eye position
      %
      function status = showEyeNow(self)
         
         status = 0;
      end
      
      % Validate calibration
      %
      function status = validateNow(self)
         
         status = 0;
      end

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
         
         % Turn on recording
         if isRecording
            Eyelink('StartRecording');
         end
         
      end % startRecording
      
      % Overloaded stopRecording method
      %
      function isRecording = stopRecording(self)
         
         % Turn off recording and close file
         Eyelink('StopRecording');
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
         
         % package up data in dotsReadable format
         newData = [ ...
            self.xID      evt.gx(self.trackedEye) evt.time; ...
            self.yID      evt.gy(self.trackedEye) evt.time; ...
            self.pupilID  evt.pa(self.trackedEye) evt.time];
         
      end % readRawEyeData
   end % Protected methods
end