classdef dotsReadableEye < dotsReadable
   % @class dotsReadableEye
   % Superclass for objects that read data from an eye tracker.
   % @details
   % dotsReadableEye extends the dotsReadable superclass with support
   % for eye trackers that measure x and y point of gaze, and pupil
   % size.
   % @details
   % <b>A note about Eye Tracker Coordinates:</b>
   % @details
   % dotsReadableEye transforms x and y position data from raw eye
   % tracker coordinates into a user-defined coordinate system that
   % might be more natural, such as degrees of visual angle.
   % @details
   % <b>Subclasses</b>
   % @details
   % dotsReadableEye itself is not a usable class.  Rather, it provides a
   % uniform interface and core functionality for subclasses.  Subclasses
   % should redefine the following methods in order to read actual data:
   %   - openDevice()
   %   - closeDevice()
   %   - calibrateDevice()
   %   - defineCompoundEvent() -> Optional, see example in dotsReadableEye
   %   - recordDevice()
   %   - openComponents()
   %   - closeComponents()
   %   .
   % These are from the dotsReadable superclass.  Subclasses must also
   % define a new method:
   %   - readRawEyeData()
   %   .
   % This method should read and return new data from the eye tracker.
   % The raw data will be transformed automatically into user-defined
   % coordinates.
   
   properties
      
      % the current "x" position of the eye in user-defined coordinates.
      x;
      
      % the current "y" position of the eye in user-defined coordinates.
      y;
      
      % the current pupil size, offset and scaled
      pupil;
      
      % The time of the most-recent sample (in ui time)
      time;
      
      % frequency in Hz of eye tracker data samples
      % @details
      % Subclasses must supply the sample frequency of their eye tracker
      % device.
      sampleFrequency;
      
      % Flag determining whether only to read event data
      %  see readNewData for details. This defaults to 'true' because
      %  typically we assume that eye tracking data will be stored
      %  separately.
      readEventsOnly = true;
      
      % helper objects including screen ensemble
      helpers;
      
      % Gaze monitor properties
      gazeMonitor = struct( ...
         'defaultWindowSize',          6.0,  ... % degrees visual angle
         'defaultWindowDuration',      0.15, ... sec
         'axisLimits',                 20,   ... % axis limits
         'samplesToShow',              200);    % samples to plot during showEye
      
      % Structure of calibration properties. Note that tolerances were
      % determined via trial-and-error and likely need adjusting for
      % different systems, contexts, subjects, ets.
      calibration = struct( ...
         'filename',                   'eyeCalibration.mat', ...
         'showMessage',                true, ... % help message
         'showOnMonitor',              true, ...
         'query',                      false, ... % Ask for input during calibration
         'queryTimeout',               5,    ... % query wait time during calibration (sec)
         'showEye',                    true, ... % automatically show eye after calibration
         'showEyeTimeout',             20,   ... % timeout for show eye calibration (sec)
         'offsetT',                    0.15, ... % Time to collect offset data (sec)
         'fullT',                      0.6,  ... % Time to collect for full calibation
         'fpX',                        10,   ... % x offset for calibration target grid
         'fpY',                        5,    ... % y offset for calibration target grid
         'fpSize',                     1.5,  ... % Size of calibration target
         'fpWaitTime',                 2.5,  ... % Time in sec of center fixation
         'transformTolerance',         5.0,  ... % 4.0,  ... % Tolerance for using calibration values
         'numberTries',                5,    ... % number of times to try calibrating
         'targetEnsemble',             [],   ... % for calibration targets
         'eyeEnsemble',                [],   ... % for showing eye position
         'uiEvents',                   struct( ... % input during calibration
         'name',      {'accept', 'calibrate', 'dritfCorrect', 'abort', 'repeat', 'showEye', 'toggle'}, ...
         'component', {'KeyboardSpacebar',  'KeyboardC', 'KeyboardD',  'KeyboardQ', 'KeyboardR',  'KeyboardS', 'KeyboardT'}));
   end
   
   properties (SetAccess = protected)
      
      % current gaze calibration properties
      gazeCalibration = struct( ...
         'timestamp',      [],   ...      % when the calibration occurred
         'xyOffset',       [0 0], ...     % how to offset raw x,y gaze data, before scaling
         'xyScale',        [1 1], ...     % how to scale raw x,y gaze data, after ofsetting
         'rotation',       [1 0; 0 1]);   % how to rotate x,y gaze data
      
      % current pupil calibration properties
      pupilCalibration = struct( ...
         'offset',         0,    ...     % how to offset pupil data, before scaling
         'scale',        	1);   ...     % how to scale pupil data, after ofsetting
         
      % integer identifier for x-position component
      xID = 1;
      
      % integer identifier for y-position data
      yID = 2;
      
      % integer identifier for pupil size data
      pupilID = 6;
      
      % Array of gazeWindow event structures
      gazeEvents = [];
   end
   
   properties (SetAccess = private)
      
      % Handle to axes showing gazeMonitor
      gazeMonitorAxes = [];
      
      % handle to the line object used to plot the eye position
      gazeMonitorDataHandle = [];
      
      % How to use gaze monitor:
      %  false = show current eye position only
      %  true = buffer eye position and show history
      % Set/unset using resetGazeBuffer method
      bufferGazeData = false;
      
      % handle to the line object used to plot the last eye position
      gazeMonitorBufferedDataHandle = [];
      
      % flag if any transformation is necessary
      doTransform = false;
      
      % for gaze windows
      cosTh = cos((0:pi/50:2*pi)');
      sinTh = sin((0:pi/50:2*pi)');
   end
   
   methods
      
      % Constructor takes no arguments.
      function self = dotsReadableEye()
         self = self@dotsReadable();
      end
      
      % Connect to eye tracker and prepare coordinate transforms.
      function initialize(self)
         self.initialize@dotsReadable();
         
         % possibly load calibration file
         if ~isempty(self.calibration.filename) && ...
               exist(fullfile(self.filepath, self.calibration.filename), 'file')
            load(fullfile(self.filepath, self.calibration.filename), 'gazeCalibration');
            self.gazeCalibration = gazeCalibration;
            self.gazeCalibration.timestamp = feval(self.clockFunction);            
         end
      end
      
      % Clear data from this object.
      % @details
      % Extends the dotsReadable flushData() method to do also clear x,
      % y, and pupul data
      function flushData(self, varargin)
         self.flushData@dotsReadable(varargin{:});
         self.x = 0;
         self.y = 0;
         self.pupil = 0;
      end
      
      % Overloaded defineEvent function
      %
      % For Eye trackers, this is a gaze window that checks whether
      %   gaze (x and y coordinates, which is why it must
      %   be defined as a "compound" event) falls into or out of a
      %   circular window.
      %
      % Required arguments:
      %  eventName   ... Name of event used by dotsReadable.getNextEvent
      %
      % Optional property/value pairs
      %  isActive    ... Flag indicating if this event is currently active
      %  isInverted  ... If true, checking for *out* of window
      %  centerXY    ... x,y coordinates of center of gaze window
      %  channelsXY  ... Indices of data channels for x,y position
      %  windowSize  ... Diameter of circular gaze window
      %  windowDur   ... How long eye must be in window (msec) for event
      %   <plus more, see below>
      function event = defineEvent(self, name, varargin)
         
         % Need a name
         if isempty(name)
            return
         end
         
         % check if it already exists
         if isempty(self.gazeEvents) || ~any(strcmp(name, {self.gazeEvents.name}))
            
            % Add window as "component"
            ID = numel(self.components) + 1;
            self.components(ID).ID = ID;
            
            % Add the new gaze window struct to the end of the array
            %   Buffer is [timestamp distance_from_center_of_window]
            index = length(self.gazeEvents) + 1;
            self.gazeEvents = cat(1, self.gazeEvents, struct( ...
               'name',             name, ...
               'ID',               ID, ...
               'channelsXY',       [self.xID self.yID], ...
               'centerXY',         [0 0], ...
               'ensemble',         [], ...
               'ensembleIndices',  [], ...
               'windowSize',       self.gazeMonitor.defaultWindowSize, ...
               'windowDur',        self.gazeMonitor.defaultWindowDuration, ...
               'isInverted',       false, ...
               'isActive',         false, ...
               'sampleBuffer',     [], ...
               'gazeWindowHandle', []));
         else
            
            % Use existing gaze window struct
            index = find(strcmp(name, {self.gazeEvents.name}));
         end
         
         % Add given args
         for ii=1:2:nargin-2
            self.gazeEvents(index).(varargin{ii}) = varargin{ii+1};
         end
         
         % Check/clear sample buffer
         len = round(self.gazeEvents(index).windowDur*self.sampleFrequency+2);
         if length(self.gazeEvents(index).sampleBuffer) ~= len
            self.gazeEvents(index).sampleBuffer = nans(len,2);
         else
            self.gazeEvents(index).sampleBuffer(:) = nan;
         end
         
         % Now add it as a new component and to the dotsReadable event
         %   queue. We do all the heavy lifting here, in getNewData, to
         %   determine if an event actually happened. As a consequence,
         %   we only send real events and don't require
         %   dotsReadable.detectEvent to make any real comparisons,
         %   which is why we set the min/max values to -/+inf.
         name = self.gazeEvents(index).name;
         ID = self.gazeEvents(index).ID;
         self.components(ID).name = ['gaze_' name];
         event = defineEvent@dotsReadable(self, name, ....
            'isActive',    self.gazeEvents(index).isActive, ...
            'isInverted',  false, ...
            'component',   ID, ...
            'lowValue',    -inf, ...
            'highValue',   inf);
         
         % Update the gaze window binding
         self.updateGazeWindows(index);
      end
      
      % Utility to update gaze windows using ensemble binding
      %
      function updateGazeWindows(self, index)
         
         if nargin < 2 || isempty(index)
            index = 1:length(self.gazeEvents);
         end
         
         for ii = index
            
            % check for ensemble binding
            if ~isempty(self.gazeEvents(ii).ensemble)
               
               % Get "bound" ensemble
               if ischar(self.gazeEvents(ii).ensemble)
                  if isfield(self.helpers, self.gazeEvents(ii).ensemble)
                     self.gazeEvents(ii).ensemble = self.helpers.(self.gazeEvents(ii).ensemble);
                  else
                     break
                  end
               end
               
               % Set values
               inds    = self.gazeEvents(ii).ensembleIndices;
               xCenter = self.gazeEvents(ii).ensemble.getObjectProperty('xCenter', inds(1));
               yCenter = self.gazeEvents(ii).ensemble.getObjectProperty('yCenter', inds(1));
               xyInd   = min(length(xCenter), inds(2));
               self.gazeEvents(ii).centerXY = [xCenter(xyInd), yCenter(xyInd)];
            end
         end
         
         % Update the gaze monitor data -- x,y positions of circle
         if self.useGUI
            self.updateGazeMonitorWindow(index);
         end
      end
      
      % Activate gaze windows
      function activateEvents(self)
         
         % Call setEventsActiveFlag to do the work
         self.setEventsActiveFlag('all');
      end
      
      % De-activate gaze windows
      function deactivateEvents(self)
         
         % Call setEventsActiveFlag to do the work
         self.setEventsActiveFlag([], 'all');
      end
      
      % Delete all compoundEvents
      function clearEvents(self)
         
         % Deactivate the current gaze events so the monitor window is
         % appropriately cleared
         self.deactivateEvents();
         
         % Now clear them
         self.gazeEvents = [];
         
         % Now clear the associated events
         clearEvents@dotsReadable(self);
      end
      
      % Set/unset activeFlag
      %
      % Recognizes keyword 'all' for activateList and deactivateList
      function setEventsActiveFlag(self, activateList, deactivateList)
         
         if isempty(self.gazeEvents)
            return
         end
         
         % Collect names of gaze events
         names = {self.gazeEvents.name};
         
         % Activate
         if nargin > 1 && ~isempty(activateList)
            if ischar(activateList)
               if strcmp(activateList, 'all')
                  [self.gazeEvents.isActive] = deal(true);
               else
                  Lind = strcmp(activateList, names);
                  if any(Lind)
                     self.gazeEvents(Lind).isActive = true;
                  end
               end
            else
               for ii = 1:length(activateList)
                  Lind = strcmp(activateList{ii}, names);
                  if any(Lind)
                     self.gazeEvents(Lind).isActive = true;
                  end
               end
            end
         else
            activateList = {};
         end
         
         % Deactivate -- need also to clear buffer(s)
         if nargin > 2 && ~isempty(deactivateList)
            if ischar(deactivateList)
               if strcmp(deactivateList, 'all')
                  deactivateList = names;
               else
                  deactivateList = {deactivateList};
               end
            end
            for ii = 1:length(deactivateList)
               Lind = strcmp(deactivateList{ii}, names);
               if any(Lind)
                  self.gazeEvents(Lind).isActive = false;
                  self.gazeEvents(Lind).sampleBuffer(:) = nan;
               end
            end
         else
            deactivateList = {};
         end
         
         % Now set flags in superclass
         setEventsActiveFlag@dotsReadable(self, activateList, deactivateList);
         
         % update the gui
         if self.useGUI
            self.updateGazeMonitorWindow();
         end
      end
      
      % Open the gaze monitor
      %
      %  Open the window and set the useGUI flag to true
      function openGazeMonitor(self, gazeMonitorAxes)
         
         % Possibly initialize the gaze monitor
         if nargin < 2 || isempty(gazeMonitorAxes)
            
            % Use the current figure
            % figure;
            clf;
            
            % Use the current axes
            self.gazeMonitorAxes = gca;
         else
            
            % Set to given axes
            self.gazeMonitorAxes = gazeMonitorAxes;
         end
         
         % setup axes
         axes(self.gazeMonitorAxes); cla reset; hold on;
         
         % Add handle to object for drawing buffered data
         self.gazeMonitorBufferedDataHandle = line(-999, -999, ...
            'Color',       'b', ...
            'Marker',      'x', ...
            'MarkerSize',  12,  ...
            'LineStyle',   'none');
         
         % Add handle to gaze data (an 'x' showing the current gaze
         % position)
         self.gazeMonitorDataHandle = line(0, 0, ...
            'Color',       'r', ...
            'Marker',      'x', ...
            'MarkerSize',  12,  ...
            'LineStyle',   'none');
         
         % Make it look nice, using static axes so plot commands don't
         % take too much time
         lims = [-self.gazeMonitor.axisLimits self.gazeMonitor.axisLimits];
         tics = -self.gazeMonitor.axisLimits:5:self.gazeMonitor.axisLimits;
         
         set(self.gazeMonitorAxes, ...
            'XLim', lims, ...
            'XTick', tics, ...
            'XGrid', 'on', ...
            'XTickLabel', tics, ...
            'XTickLabelMode', 'manual', ...
            'YLim', lims, ...
            'YTick', tics, ...
            'YTickLabel', tics, ...
            'YTickLabelMode', 'manual', ...
            'YGrid', 'on', ...
            'box',   'on', ...
            'FontSize', 12)
         xlabel('Horizontal eye position (deg)')
         ylabel('Vertical eye position (deg)')
         
         % Monitor is on
         self.useGUI = true;
      end
      
      % Close the gaze monitor
      %
      % For now just turn the flag off, but don't do anything else
      function closeGazeMonitor(self)
         
         % Monitor is off
         self.useGUI = false;
      end
      
      % Utilities for changing calibration offsets (e.g., via GUI)
      function incrementCalibrationOffsetX(self, increment)
         self.setEyeCalibration(self.gazeCalibration.xyOffset + [increment 0], [], []);
      end
      
      function incrementCalibrationOffsetY(self, increment)
         self.setEyeCalibration(self.gazeCalibration.xyOffset + [0 increment], [], []);
      end
      
      % Set the calibration parameters and dump to the data log.
      %  This is public in case you want to set these by hand for some
      %  reason
      function setEyeCalibration(self, xyOffsets, xyScales, rotations)
         
         % Conditionally set the inputs..note that all arguments must
         %  be given, but use [] as flag not to change
         if ~isempty(xyOffsets)
            self.gazeCalibration.xyOffset = xyOffsets;
         end
         if ~isempty(xyScales)
            self.gazeCalibration.xyScale = xyScales;
         end
         if ~isempty(rotations)
            self.gazeCalibration.rotation = rotations;
         end
         
         % check if the tranformation parameters are used
         if any(self.gazeCalibration.xyOffset~=0) || ...
               any(self.gazeCalibration.xyScale~=1) || ...
               any(self.gazeCalibration.rotation(:)~=[1 0 0 1]')
            self.doTransform = true;
         else
            self.doTransform = false;
         end
         
         % Save it to the log
         self.gazeCalibration.timestamp = self.getDeviceTime();
         topsDataLog.logDataInGroup(self.gazeCalibration, ['calibrate ' class(self)]);
      end      
   end
   
   methods (Access = protected)
      
      % Declare x, y, and pupil components.
      % Use overloaded subclass openComponents Method
      %  to redefine if necessary
      function components = openComponents(self)
         
         % The component names
         names = {'x', 'y', 'pupil'};
         
         % Make the components
         components = struct('ID', num2cell(1:size(names,1)), 'name', names);
         
         % Save IDs
         self.xID = find(strcmp('x', names));
         self.yID = find(strcmp('y', names));
         self.pupilID = find(strcmp('pupil', names));
      end
      
      % calibrateDevice
      %
      % Calibrate the eye tracker with respect to snow-dots coordinates
      %   and put in units of deg vis angle
      %
      % Optional arguments to recenter only
      %   1: mode flag:
      %     'c'      calibrate
      %     'v'      validate
      %     's'      show eye position
      %     'd'      drift correction
      %   2: optional x,y values of current gaze for drift correcton
      %
      % Returns:
      %  status = 0 if calibrated within tolerance, 1 if error
      %
      function status = calibrateDevice(self, mode, varargin)
         
         if nargin < 2 || isempty(mode)
            mode = 'c';
         end
         
         % get the user-input device used to give responses during calibration
         %
         if isempty(self.calibrationUI)
            if isa(self, 'dotsReadableEyeMouseSimulator')
               
               % special case of mouse simulator -- use mouse click
               self.calibrationUI = self.HIDmouse;
               
               % Deactivate all events
               self.calibrationUI.deactivateEvents();
               
               % Set button 1 to accept
               ids = getComponentIDs(self.HIDmouse);
               self.calibrationUI.defineEvent('accept', 'isActive', true, 'component', ids(3));
            else
               
               % use the keyboard
               self.calibrationUI = dotsReadableHIDKeyboard();
               
               % Deactivate all events
               self.calibrationUI.deactivateEvents();
               
               % Now add given events. Note that the third and fourth arguments
               %  to defineCalibratedEvent are Calibrated value and isActive --
               %  we could make those user controlled.
               self.calibrationUI.defineEventsFromStruct(self.calibration.uiEvents);
            end
            
            % Read during calls to get next event
            self.calibrationUI.isAutoRead = true;
         end
         
         % Flush events and make sure no keys are being pressed
         %
         self.calibrationUI.flushData(true);
         
         % Generate Fixation target (cross)
         %
         % We will create a single drawable object to represent the fixation cue.
         % Then, we simply adjust the location of the cue each time we present it.
         if isempty(self.calibration.targetEnsemble)
            
            % make the target ensemble
            fixationCue        = dotsDrawableTargets();
            fixationCue.width  = [1 0.1] * self.calibration.fpSize;
            fixationCue.height = [0.1 1] * self.calibration.fpSize;
            self.calibration.targetEnsemble = dotsDrawable.makeEnsemble( ...
               'targetEnsemble', {fixationCue});
            
            % make the eye ensemble
            eyeCue                       = dotsDrawableTargets();
            eyeCue.width                 = 0.5;
            eyeCue.height                = 0.5;
            eyeCue.isColorByVertexGroup  = true;
            self.calibration.eyeEnsemble = dotsDrawable.makeEnsemble( ...
               'eyeEnsemble', {eyeCue});
         end
         
         % Default no error
         status = 0;
         
         % Check for calibration/drift correction mode
         %
         switch mode
            
            case {'d' 'D'}
               
               % Drift correction
               self.driftCorrect(varargin{:});
               
            case {'s' 'S'}
               
               % Show eye position
               self.showEyePosition();
               
            otherwise % case {'c' 'C'}
               
               % Calibration
               isCalibrated = false;
               while ~isCalibrated
                  
                  % Status is typically a dummy -- here we ask for
                  % feedback
                  self.calibrateNow();
                  
                  if ~self.useExistingCalibration && self.calibration.query && ...
                        isa(self.calibrationUI, 'dotsReadableHIDKeyboard')
                     
                     % Show message
                     if self.calibration.showEye
                        disp('space or s to show eye, r to repeat calibration, q to finish')
                     else
                        disp('s to show eye, r to repeat calibration, space or q to finish')
                     end
                     
                     % Wait for keyboard input
                     [didHappen, ~, ~, ~, nextEvent] = dotsReadableHIDKeyboard.waitForKeyPress( ...
                        self.calibrationUI, [], self.calibration.queryTimeout, true, true);
                     
                     % Made it through timeout, just continue.
                     if ~didHappen
                        nextEvent = 'accept';
                     end
                     
                     if ~strcmp(nextEvent, 'repeat')
                        isCalibrated = true;
                        
                        % possibly show eye
                        if ~strcmp(nextEvent, 'abort') && ...
                              (self.calibration.showEye || strcmp(nextEvent, 'showEye'))
                           self.showEyePosition();
                        end
                     end
                  else
                     isCalibrated = true; % no feedback, just finish
                  end
               end
         end
      end
      
      % driftCorrect
      %
      % Do drift correction. Optional argument is x,y location of
      %  current gaze or index of gazeWindow to use
      function driftCorrect(self, currentXY, showTarget)
         
         % check args
         if nargin < 2 || isempty(currentXY)
            currentXY = [0 0];
         elseif length(currentXY)==1
            currentXY = self.gazeEvents(currentXY).centerXY;
         end
         
         % possibly show target
         if nargin >= 3 && showTarget
            self.calibration.targetEnsemble.setObjectProperty('xCenter', currentXY(1));
            self.calibration.targetEnsemble.setObjectProperty('yCenter', currentXY(2));
            self.calibration.targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            % wait to settle
            pause(0.3);
         else
            showTarget = false;
         end
         
         % Get current fixation
         fixXY = self.getFixation(self.calibration.offsetT, false, true);
         
         % Possibly hide target
         if showTarget
            dotsTheScreen.blankScreen();
         end
         
         % Now add the offsets if within tolerance, and flush the queue
         % of the older, uncalibrated samples
         % var(gazeXY)
         if ~isempty(fixXY)
            self.setEyeCalibration(self.gazeCalibration.xyOffset + ...
               currentXY - fixXY, [], []);
            self.flushData();
         else
            disp('dotsReadableEye calibration recenter failed')
         end
      end
      
      % showEyePosition
      %
      % Read and plot eye position
      function showEyePosition(self)
         
         % Help message
         disp('In showEyePosition. Press <space> to exit')
         
         % Get ensemble of target objects to show as eye position
         eyeEnsemble = self.calibration.eyeEnsemble;
         
         % blank the screen
         dotsTheScreen.blankScreen();
         
         % keep history
         xyData = nans(self.gazeMonitor.samplesToShow, 5);
         xyData(:,3:5) = repmat(linspace(0,1,self.gazeMonitor.samplesToShow)',1,3);
         lastTime = -9999;
         
         % Get frame interval
         screenEnsemble = dotsTheScreen.theEnsemble();
         fi = 1/screenEnsemble.getObjectProperty('windowFrameRate', 1);
         
         % Call startTrial to possibly initialize input device
         % Note that the buffer size for the device (e.g., EOG)
         %  should be smaller than the timeout duration
         self.startTrial();
         
         % Loop until timeout or spacebar
         self.calibrationUI.setEventsActiveFlag('accept');
         startTime = feval(self.clockFunction);
         while (feval(self.clockFunction) - startTime) < self.calibration.showEyeTimeout && ...
               ~strcmp(self.calibrationUI.getNextEvent(), 'accept')
            
            % Get all new events
            t1 = tic;
            count = 0;
            while toc(t1) < fi - 0.002 % leave some flip time
               
               % Read the new data
               self.read();
               
               % rotate buffer
               if self.time > lastTime
                  lastTime            = self.time;
                  xyData(1:end-1,1:2) = xyData(2:end,1:2);
                  xyData(end,1:2)     = [self.x self.y];
                  count = count + 1;
               end
            end
            
            % update the drawable
            Lgood = ~isnan(xyData(:,1));
            
            % Show it!
            if any(Lgood)
               eyeEnsemble.setObjectProperty('xCenter', xyData(Lgood,1));
               eyeEnsemble.setObjectProperty('yCenter', xyData(Lgood,2));
               eyeEnsemble.setObjectProperty('colors',  xyData(Lgood,3:5));
               eyeEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            end
         end
         
         % Call finishTrial method (e.g., for EOG)
         self.finishTrial();
         
         % Deactivate the accept event
         self.calibrationUI.setEventsActiveFlag({}, 'accept');
         
         % blank the screen
         dotsTheScreen.blankScreen();
      end
      
      % calibrateNow
      %
      % Calibrate with respect to screen coordinates
      % Can be overloaded. Returns 0=good, 1=error
      function status = calibrateNow(self)
         
         % Initialize
         status = 1; % not calibrated
         
         % get the ensemble
         targetEnsemble = self.calibration.targetEnsemble;
         
         % Show a help message
         if self.calibration.showMessage
             dotsDrawableText.showText({'Please look at each object and', ...
                 'maintain fixation while it is showing.'}, ...
                 'showDuration',  5.0, ...
                 'pauseDuration', 0.3);
         end
         
         % Pause for graphics to initialize
         pause(1.0);
         
         % Set up matrices to present cues and collect fixation data
         if self.calibration.fpY>0 && self.calibration.fpX>0
            
            % Horizontal and vertical calibration
            targetXY = [ ...
               0   self.calibration.fpY;
               self.calibration.fpX  0;
               0 -self.calibration.fpY;
               -self.calibration.fpX  0];
            
         elseif self.calibration.fpY>0
            
            % Vertical calibration only
            targetXY = [ ...
               0   self.calibration.fpY;
               0 -self.calibration.fpY];
            
         elseif self.calibration.fpY>0
            
            % Horizontal calibration only
            targetXY = [ ...
               -self.calibration.fpX  0;
               self.calibration.fpX  0];
            
         else
            
            % No calibration
            return
         end
         
         % Set up data structures for fixation data
         numFixations = size(targetXY, 1);
         gazeXY       = nans(numFixations, 2);
         
         % Set up monitor graphics objects for feedback
         if self.calibration.showOnMonitor
            colors = {'r' 'g' 'b' 'c'};
            htgt = plot(targetXY(:,1), targetXY(:,2), 'k+', 'MarkerSize', 15);
            hraw = gobjects(numFixations); % raw
            htrn = gobjects(numFixations); % transformed
            for ii = 1:numFixations
               hraw(ii) = plot(0, 0, 'o', 'MarkerSize', 6,  'MarkerFaceColor', colors{ii});
               htrn(ii) = plot(0, 0, 's', 'MarkerSize', 10, 'MarkerFaceColor', colors{ii});
            end
         end
         
         % uncomment (plus in get Fixation) for debugging
         % fi = figure;
         % pause(4);
         
         % Loop through calibration tries, save best
         for tt = 1:self.calibration.numberTries
            
            % For debugging
            % figure(fi);
            
            % Loop through each target to get eye position samples
            index = 1;
            numTries = 1;
            while index <= numFixations && numTries < self.calibration.numberTries
               
               % Show the fixation cross in the center to get things started
               targetEnsemble.setObjectProperty('xCenter', 0);
               targetEnsemble.setObjectProperty('yCenter', 0);
               
               targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               pause(self.calibration.fpWaitTime);
               
               % Show the fixation point
               targetEnsemble.setObjectProperty('xCenter', targetXY(index,[1 1]));
               targetEnsemble.setObjectProperty('yCenter', targetXY(index,[2 2]));
               targetEnsemble.setObjectProperty('colors',  [1 1 1]);
               targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               
               % flush the eye data
               self.flushData();
               
               % Start the device
               self.startTrialDevice();
               
               % for debugging
               % subplot(4,1,ii); cla reset; hold on;
               
               % Get fixation
               vals = self.getFixation(self.calibration.fullT, true, false);
               
               % Save good data
               if ~isempty(vals)
                  gazeXY(index,:) = vals;
                  index = index + 1;
               end
               
               % increment tries
               numTries = numTries + 1;
               
               % Finish the device
               self.finishTrialDevice();
               
               % Flash red, pause for pacing
               targetEnsemble.setObjectProperty('colors',  [1 0 0]);
               targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               pause(0.2);
               targetEnsemble.setObjectProperty('colors',  [1 1 1]);
               targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               pause(1.0);
            end
            
            % Clean up display
            dotsTheScreen.blankScreen();
            
            % Calibrate differently if horizontal/vertical only or both
            % Set up matrices to present cues and collect fixation data
            if self.calibration.fpY>0 && self.calibration.fpX>0
               
               % Horizontal and vertical calibration
               % Get vectors connecting each point
               diffTargetXY = diff([targetXY; targetXY(1,:)]);
               diffGazeXY   = diff([gazeXY; gazeXY(1,:)]);
               
               % Select x,y directions
               Lx = diffTargetXY(:,1)~=0;
               Ly = diffTargetXY(:,2)~=0;
               
               % Calculate average x,y scaling
               xyScaleVals = [ ...
                  mean(diffTargetXY(Lx,1) ./ diffGazeXY(Lx,1)) ...
                  mean(diffTargetXY(Ly,2) ./ diffGazeXY(Ly,2))];
               
               % Calculate average rotation
               angs = nans(numFixations, 1);
               for ii = 1:numFixations
                  u = [diffTargetXY(ii,:) 0];
                  v = [diffGazeXY(ii,:) 0];
                  angs(ii) = atan2(norm(cross(u,v)),dot(u,v));
               end
               ang = mean(angs);
               rotationVals = [cos(ang) -sin(ang); sin(ang) cos(ang)];
               
               % Calculate average x,y offset
               xyOffsetVals = mean(targetXY -  ...
                  [xyScaleVals(1).*gazeXY(:,1) xyScaleVals(2).*gazeXY(:,2)] * ...
                  rotationVals);
               
            else
               
               % Horizontal/Vertical calibration only
               diffTargets  = diff(targetXY);
               diffGazes    = diff(gazeXY);
               rotationVals = [1 1; 1 1];
               
               if self.calibration.fpY>0
                  
                  % Vertical
                  xyScaleVals  = [0 diffTargets(2)/diffGazes(2)];
                  xyOffsetVals = [0 mean(targetXY(:,2)) - mean(gazeXY(:,2))];
               else
                  
                  % Horizontal
                  xyScaleVals  = [diffTargets(1)/diffGazes(1) 0];
                  xyOffsetVals = [mean(targetXY(:,1)) - mean(gazeXY(:,1)) 0];
               end
            end            
            
            % Compute and show errors
            transformedData = ...
               [xyScaleVals(1).*gazeXY(:,1) xyScaleVals(2).*gazeXY(:,2)] * ...
               rotationVals + repmat(xyOffsetVals, size(gazeXY,1), 1);
            errors = sqrt(sum((targetXY-transformedData).^2,2));            
            disp(' ')
            disp(errors)
            
            % Show calibration markers on monitor
            if self.calibration.showOnMonitor
               for ii = 1:numFixations
                  set(hraw(ii), 'XData', gazeXY(ii,1), 'YData', gazeXY(ii,2));
                  set(htrn(ii), 'XData', transformedData(ii,1), 'YData', transformedData(ii,2));
               end
               drawnow;
               pause(4.0);
            end
            
            % Check tolerance and accept/leave if within range
            if all(errors < self.calibration.transformTolerance)
               
               % Set the current calibration
               self.setEyeCalibration(xyOffsetVals, xyScaleVals, rotationVals);
               
               % save the raw points as well, to re-check calibration later
               topsDataLog.logDataInGroup({targetXY, gazeXY}, ['calibrate raw' class(self)]);
               
               % Possibly save the calibration
               if ~isempty(self.calibration.filename)
                  gazeCalibration = self.gazeCalibration;
                  save(fullfile(self.filepath, self.calibration.filename), 'gazeCalibration');
               end
               
               status = 1;
               break
            end
            
            % Trying again
            disp('ERRORS OUT OF RANGE!')
         end
         
         % Clean up eye monitor
         if self.calibration.showOnMonitor
            delete(htgt);
            delete(hraw);
            delete(htrn);
            axes(self.gazeMonitorAxes);
            axis([-20 20 -20 20]);
         end
      end
      
      % Possibly buffer and recenter gaze
      %
      % Arguments:
      %  1. recenter    ... if true, recenter to [0 0]
      %                  or use given values
      %  2. useBuffer   ... flag to stop/start buffering
      function resetDevice(self, varargin)
         
         % Conditionally re-center gaze (drift correct)
         if nargin > 1
            if isnumeric(varargin{1}) && length(varargin{1})==2
               self.calibrate('d', varargin{1});
            elseif ~(islogical(varargin{1}) && ~varargin{1})
               self.calibrate('d');
            end
         end
         
         % Conditionally set useBuffer flag
         if nargin > 2 && ~isempty(varargin{2})
            self.bufferGazeData = varargin{2};
         end
         
         set(self.gazeMonitorBufferedDataHandle, ...
            'XData', [], ...
            'YData', []);
      end
      
      % Close the components and release the resources.
      %
      function closeComponents(self)
         self.components = [];
         self.isAvailable = false;
      end
      
      % Read and format incoming data (for subclasses).
      % @details
      % Extends the readNewData() method of dotsReadable to also
      % transform x, y, and pupil data into user-defined coordinates.
      function newData = readNewData(self)
         
         % Default
         newData = [];
         
         % get new data
         rawData = self.readRawEyeData();
         if isempty(rawData)
            return
         end
         
         % Possibly transform
         if self.doTransform
            rawData = self.transformRawData(rawData);
         end
         
         % check whether or not we pass along all the raw data
         %  or just the events
         if ~self.readEventsOnly
            newData = rawData;
         end
         
         % NOTE: FOR NOW ASSUME THAT ALL EVENTS USE THE SAME (DEFAULT) GAZE
         % CHANNELS!!! THIS CAN/SHOULD BE CHANGED IF MORE FLEXIBILITY IS
         % NEEDED, BUT FOR NOW IT SERVES TO SPEED THINGS UP
         % Get x,y samples ... these should be paired
         Lx = rawData(:,1) == self.xID;
         Ly = rawData(:,1) == self.yID;
         
         % Check for relevant data
         if ~any(Lx) || sum(Lx) ~= sum(Ly)
            if sum(Lx) ~= sum(Ly) % This shouldn't happen
               warning('dotsReadableEye.readNewData: error')
            end
            return
         end
         
         % collect into [time x y] triplets
         gazeData = cat(2, rawData(Lx,3), rawData(Lx,2), rawData(Ly,2));
         numSamples = size(gazeData, 1);
         
         % Save the current gaze
         self.time = gazeData(end,1);
         self.x    = gazeData(end,2);
         self.y    = gazeData(end,3);
         
         % disp(gazeData(end,2:3))
         % Possibly update monitor window
         if ~isempty(self.gazeMonitorDataHandle)
            if self.bufferGazeData
               xd  = get(self.gazeMonitorDataHandle, 'XData');
               yd  = get(self.gazeMonitorDataHandle, 'YData');
               xde = get(self.gazeMonitorBufferedDataHandle, 'XData');
               yde = get(self.gazeMonitorBufferedDataHandle, 'YData');
               set(self.gazeMonitorBufferedDataHandle, ...
                  'XData', cat(2, xde, xd), ...
                  'YData', cat(2, yde, yd));
            end
            
            % always set the current data points
            set(self.gazeMonitorDataHandle, ...
               'XData', self.x, ...
               'YData', self.y);
            
            % Only draw if not buffering
            if ~self.bufferGazeData
               drawnow;
            end
         end
         
         if isempty(self.gazeEvents)
            return
         end
         
         % Now loop through each active gaze window and update each
         %   gaze window data by computing distance of gaze
         %   to center of each window
         for ii = find([self.gazeEvents.isActive])
            
            % Get the gaze event struct, for convenience
            ev = self.gazeEvents(ii);
            % disp(sprintf('checking <%s>', ev.name))
            
            % Calcuate number of samples to add to the buffer
            numSamplesToAdd = min(size(ev.sampleBuffer,1), numSamples);
            
            % Rotate the buffer
            ev.sampleBuffer(1:end-numSamplesToAdd,:) = ...
               ev.sampleBuffer(1+numSamplesToAdd:end,:);
            
            % Add the new samples:
            % [<timestamp> <distance from center>]
            inds = (numSamples-numSamplesToAdd+1):numSamples;
            ev.sampleBuffer(end-numSamplesToAdd+1:end,:) = [
               gazeData(inds, 1), ...
               sqrt( ...
               (gazeData(inds,2)-ev.centerXY(1)).^2 + ...
               (gazeData(inds,3)-ev.centerXY(2)).^2)];
            
            % Save the event struct back in the object
            self.gazeEvents(ii)=ev;
            
            % Check for event:
            %  1. current sample is in acceptance window
            %  2. at least one other sample is in acceptance window
            %  3. earlist sample in acceptance window was at least
            %     historyLength in the past
            %  4. no intervening samples were outside window
            if ev.isInverted
               
               % Looking for ALL samples outside window
               Lgood = ev.sampleBuffer(:,2) > ev.windowSize;
               
               if Lgood(end) && any(Lgood(1:end-1))
                  fg = find(Lgood,1);
                  if (ev.sampleBuffer(fg,1) <= ...
                        (ev.sampleBuffer(end,1) - ev.windowDur)) && ...
                        (all(Lgood(fg:end) | ~isfinite(ev.sampleBuffer(fg:end,2))))
                     
                     % Add the event to the data stream
                     newData = cat(1, newData, ...
                        [ev.ID ev.sampleBuffer(fg,[2 1])]);
                  end
               end
               
            else
               
               % Looking for first/last samples inside window
               Lgood = ev.sampleBuffer(:,2) <= ev.windowSize;
               
               if Lgood(end) && any(Lgood(1:end-1))
                  fg = find(Lgood,1);
                  if (ev.sampleBuffer(fg,1) <= ...
                        (ev.sampleBuffer(end,1) - ev.windowDur)) %&& ...
                     %  (all(Lgood(fg:end) | ~isfinite(ev.sampleBuffer(fg:end,2))))
                     
                     % Add the event to the data stream
                     newData = cat(1, newData, ...
                        [ev.ID ev.sampleBuffer(fg,[2 1])]);
                  end
               end
            end
         end
      end
      
      %% Read and format raw eye tracker data (for subclasses).
      % @details
      % Subclasses must redefine readRawEyeData() to read and return raw
      % data from the eye tracker.  readRawEyeData() should use xID, yID
      % and pupilID to identify x, y, and pupil component data.  Data
      % using these IDs will be transformed automatically into
      % user-defined coordinates.
      function newData = readRawEyeData(self)
         newData = zeros(0,3);
      end
      
      %% transformRawData
      %
      % Replace x, y, and pupil data with transformed data.
      %
      % Arguments:
      %  newData ... assumes a nx3 matrix
      %              rows are:
      %                 <ID> <value> <timestamp>
      %              columns are:
      %                 1. x position
      %                 2. y position
      %                 3. (optional) pupil diameter
      function data = transformRawData(self, data, ids)
         
         % check for data
         if ~isempty(data)
            
            if nargin < 3 || isempty(ids)
               Lx = data(:,1) == self.xID;
               Ly = data(:,1) == self.yID;
            else
               Lx = data(:,1) == ids(1);
               Ly = data(:,1) == ids(2);
            end
            
            newXY = dotsReadableEye.calibrateXY( ...
               [data(Lx,2) data(Ly,2)], self.gazeCalibration);
            
            data(Lx,2) = newXY(:,1);
            data(Ly,2) = newXY(:,2);
         end
      end
      
      %% Get current fixation
      %
      function fixXY = getFixation(self, timeout, waitForSaccade, doTransform)
         
         % Check arg
         if nargin < 2 || isempty(timeout)
            timeout = 1.0;
         end
         
         % Collect the data
         newData = [];
         startTime = feval(self.clockFunction);
         while feval(self.clockFunction) < startTime + timeout
            newData = cat(1, newData, self.readRawEyeData);
         end
         
         % Possibly transform
         if nargin >= 4 && doTransform
            newData = self.transformRawData(newData);
         end
         
         % Get x, y
         xs = newData(newData(:,1)==self.xID, 2);
         ys = newData(newData(:,1)==self.yID, 2);
         
         % Check for saccade or not
         if nargin >= 3 && waitForSaccade
            
            % assume two fixations, before and after saccade
            % parse by finding index that minimizes difference from median
            % values before and after the index
            errs = nans(length(xs), 1);
            for ii = 1:length(xs)-1
               errs(ii) = sum( [sqrt((xs(1:ii)-median(xs(1:ii))).^2 + ...
                  (ys(1:ii)-median(ys(1:ii))).^2);  ...
                  sqrt( (xs(ii+1:end)-median(xs(ii+1:end))).^2 + ...
                  (ys(ii+1:end)-median(ys(ii+1:end))).^2)] );
            end
            ind = find(errs==min(errs),1);
            fixXY = median([xs(ind:end) ys(ind:end)]);
         else
            fixXY = median([xs ys]);
         end
         
         % For debugging
         %          plot(xs, 'b-');
         %          plot(ys, 'r-');
         %          plot([0 250], fixXY([1 1]), 'b-')
         %          plot([0 250], fixXY([2 2]), 'r-')
      end
   end
   
   % These methods are called only by local functions
   methods (Access = private)
      
      % Set up the gaze monitor and update the gazeWindow (circle)
      % associted with the given index
      function updateGazeMonitorWindow(self, index)
         
         if nargin < 2 || isempty(index)
            index = 1:length(self.gazeEvents);
         end
         
         for ii = index
            
            % Possibly make a handle to the line object that we'll use to
            % draw the gaze window circle
            if isempty(self.gazeEvents(ii).gazeWindowHandle)
               axes(self.gazeMonitorAxes);
               self.gazeEvents(ii).gazeWindowHandle = line(0,0);
            end
            
            % If active, update the data to draw the circle
            if self.gazeEvents(ii).isActive
               
               % Draw the circle
               if self.gazeEvents(ii).isInverted
                  lineStyle = ':';
               else
                  lineStyle = '-';
               end
               set(self.gazeEvents(ii).gazeWindowHandle, ...
                  'XData', ...
                  self.gazeEvents(ii).windowSize * self.cosTh + ...
                  self.gazeEvents(ii).centerXY(1), ...
                  'YData', ...
                  self.gazeEvents(ii).windowSize * self.sinTh + ...
                  self.gazeEvents(ii).centerXY(2), ...
                  'LineStyle', ...
                  lineStyle);
            else
               
               % Remove the circle from the gaze monitor
               set(self.gazeEvents(ii).gazeWindowHandle, ...
                  'XData', 0, 'YData', 0);
            end
         end
         
         % Check for any gaze windows. If not, clear gaze data buffer.
         if isempty(self.gazeEvents) || ~any([self.gazeEvents.isActive])
            
            % Clear the gaze window data buffer
            set(self.gazeMonitorBufferedDataHandle, ...
               'XData', [], ...
               'YData', []);
         end
         
         % update the plot
         drawnow;
      end
   end
   
   methods (Static)
      
      % Utility for using a topsDataLog 'dotsReadableEye calibration'
      %  item to calibrate gaze for a single chunk of data
      %
      %  gazeCalibration is the structure in the property list, above, with
      %  fields:
      %     1. timestamp
      %     2. xyOffset
      %     3. xyScale
      %     4. rotation
      function calibratedXY = calibrateXY(rawXY, gazeCalibration)
         
         numSamples = size(rawXY, 1);
         if numSamples > 0
            
            % Scale, rotate, then offset
            calibratedXY = [ ...
               gazeCalibration.xyScale(1).*rawXY(:,1) ...
               gazeCalibration.xyScale(2).*rawXY(:,2)] * ...
               gazeCalibration.rotation + repmat(gazeCalibration.xyOffset, numSamples, 1);
         else
            calibratedXY = [];
         end
      end
      
      % Utility for calibrating gaze using an array of structures
      % containing 'dotsReadableEye calibration' items
      %
      % Raw values columns are time, gaze_x, gaze_y
      function calibratedValues = calibrateGazeSets(rawValues, gazeCalibrations)
         
         % Make array of calibration timestamps ... remember 
         %  these are in local (device) time
         gazeCalibration = cat(1, gazeCalibrations.item);
         calibrationTimes = cat(1, gazeCalibration.timestamp, inf);
         
         % Calibrate gaze, in chunks
         for cc = 1:size(calibrationTimes,1)-1
            
            % get relevant samples
            Lcal = rawValues(:,1) >= calibrationTimes(cc) & ...
               rawValues(:,1) < calibrationTimes(cc+1);
            
            % transform
            rawValues(Lcal,2:3) = dotsReadableEye.calibrateXY( ...
               rawValues(Lcal,2:3), gazeCalibration(cc));
         end
         calibratedValues = rawValues;
      end      
      
      % Utility to parse raw data and return a standardized structure
      %
      % Arguments:
      %  1. data     ... matrix of sampled data
      %  2. tags     ... string names of data columns
      %  3. syncData ... matrix of synchronization data with columns
      %                       referenceTime
      %                       offset
      function analog = parseRawData(data, tags, syncData)
         
         % Make the default structure
         analog = struct(     ...
            'name',         {tags}, ...   % 1xn" cell array of strings
            'acquire_rate', [],   ...     % 1xn array of #'s, in Hz
            'store_rate',   round(1/median(diff(data(:,1)))),   ... % 1xn" array of #'s, in Hz
            'error',        {{}}, ...     % mx1  array of error messages
            'data',         {{}});        % mxn" cell array

         if nargin >= 3 && ~isempty(syncData)
            
            % Create the data structure
            
            % Get the time column (and make sure it is first)
            eti = find(strcmp(tags, 'time'));
            if eti ~= 1
               error('dotsReadableEye.parseRawData: time must be first column')
            end
            numTrials = length(syncData);
            analog.data = cell(numTrials, 1);
            syncData(end+1,:) = inf;
            
            % Loop through the trials and get the data
            for tt = 1:numTrials
               
               % Use current offset for timestamps
               times = data(:,1)+syncData(tt,2);
               
               % Get gaze data
               Lgaze = times >= syncData(tt,1) & times < syncData(tt+1,1);
               
               % Put eye data in order: time, x, y, etc
               analog.data{tt} = cat(2, times(Lgaze)-times(find(Lgaze,1)), data(Lgaze, 2:end));
            end
         end
      end
   end
end