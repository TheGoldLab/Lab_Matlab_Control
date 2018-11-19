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
         'defaultWindowSize',          3.0,  ... % degrees visual angle
         'defaultWindowDur',           0.2,  ... sec
         'axisLimits',                 20,   ... % axis limits
         'samplesToShow',              1000);    % samples to plot during showEye
      
      % Structure of calibration properties. Note that tolerances were
      % determined via trial-and-error and likely need adjusting for
      % different systems, contexts, subjects, ets.
      calibration = struct( ...
         'showMessage',                true, ... % help message
         'query',                      false, ... % Ask for input during calibration
         'queryTimeout',               5,    ... % query wait time during calibration (sec)
         'showEye',                    true, ... % automatically show eye after calibration
         'offsetN',                    30,   ... % Number of samples to collect for calibration offset
         'fullN',                      100,  ... % Number of samples to collect for full calibation
         'fpX',                        10,   ... % x offset for calibration target grid
         'fpY',                        5,    ... % y offset for calibration target grid
         'fpSize',                     1.5,  ... % Size of calibration target
         'varTolerance',               5, ...  %0.0001, ... % Tolerance for using calibration values
         'offsetVarTolerance',         2.0,  ... % Tolerance for using calibration values
         'transformTolerance',         15.0, ... % 4.0,  ... % Tolerance for using calibration values
         'numberTries',                5,    ... % number of times to try calibrating
         'targetEnsemble',             [],   ... % for calibration targets
         'eyeEnsemble',                [],   ... % for showing eye position
         'uiEvents',    struct( ... % input during calibration
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
      pupilID = 3;
      
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
      end
      
      % Clear data from this object.
      % @details
      % Extends the dotsReadable flushData() method to do also clear x,
      % y, and pupul data
      function flushData(self)
         self.flushData@dotsReadable();
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
               'windowDur',        self.gazeMonitor.defaultWindowDur, ...
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
               self.gazeEvents(ii).centerXY = [xCenter(inds(2)), yCenter(inds(2))];
            end
         end
         
         % Update the gaze monitor data -- x,y positions of circle
         if self.useGUI
            self.updateGazeMonitorWindow(index);
         end
      end

      % Utility to set gaze window size/durations
      %
      function setGazeWindows(self, windowSize, windowDuration)
         
         % Check for windows
         numWindows = length(self.gazeEvents);
         if numWindows == 0
            return
         end
         
         % Check args -- size
         if nargin < 2
            windowSize = [];
         elseif length(windowSize) < numWindows
            windowSize(end+1:numWindows) = windowSize(end);
         end
         
         % Check args -- duration
         if nargin < 3
            windowDuration = [];
         elseif length(windowDuration) < numWindows
            windowDuration(end+1:numWindows) = windowDuration(end);
         end
         
         % Set each window size, duration
         for ii = 1:numWindows
            if ~isempty(windowSize)
               self.gazeEvents(ii).windowSize = windowSize(ii);
            end
            if ~isempty(windowDuration)
               self.gazeEvents(ii).windowDur = windowDuration(ii);
            end
            
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
         self.gazeCalibration.timestamp = feval(self.clockFunction);
         topsDataLog.logDataInGroup(self.gazeCalibration, 'dotsReadableEye calibration');
      end
      
      % Overloaded utility to get data and put it in FIRA analog format
      %
      % Arguments:
      %  1. dotsReadableEye object
      %  2. filename with path
      %  3. syncTimes is an nx2 matrix, values are times, columns are:
      %        1. local start time
      %        2. ui start time
      %        3. trial reference time
      %  4. self.gazeCalibration is tagged calibration data from the
      %  topsDataLog, each item is:
      %      	1. timestamp
      %       	2. xyOffset
      %      	3. xyScale
      %       	4. rotation matrix
      function analog = readDataFromFile(self, filename, syncTimes, gazeCalibration)
         
         % Get the raw data and tags
         %
         [rawData, tags] = self.readRawDataFromFile(filename);
         
         % get data indices
         eti = find(strcmp(tags, 'time'));
         exi = find(strcmp(tags, 'gaze_x'));
         eyi = find(strcmp(tags, 'gaze_y'));
         eci = find(strcmp(tags, 'confidence'));
         epi = find(strcmp(tags, 'pupil'));
         
         % Conditionally synchronize timing to local timeframe
         %
         if nargin >= 3 && ~isempty(syncTimes)
            
            % Make the new time matrix
            newTimes = nans(size(rawData(:,1),1),1);
            
            % Make a temporary array to keep track of difference between each value of
            %  "oldTimes" and the current referent
            diffTimes = inf.*ones(size(newTimes));
            
            % Loop through each synch pair
            for tt = 1:size(syncTimes,1)
               
               % Find all gaze timestamps that are closer to the current sync time
               % than anyting checked previously, and save them
               diffs = abs(rawData(:,eti)-syncTimes(tt,2));
               Lsync = diffs < diffTimes;
               diffTimes(Lsync) = diffs(Lsync);
               
               % Use this sync pair for nearby timestamps
               newTimes(Lsync) = rawData(Lsync,eti) - syncTimes(tt,2) + syncTimes(tt,1);
            end
            
            rawData(:,eti) = newTimes;
         end
         
         % Conditionally calibrate the raw eye signals
         %
         if nargin >= 4 && ~isempty(gazeCalibration)
            
            % expects time, gx, gy
            rawData(:,[eti exi eyi]) = dotsReadableEye.calibrateGazeSets( ...
               rawData(:,[eti exi eyi]), gazeCalibration);
         end
         
         % Collect trial-wise data
         %
         % For each trial (row in ecodes), make a cell array of pupil data
         %  timestamp, gaze x, gaze y, confidence, and re-code time wrt to fp onset.
         %  Also put everything in local time, wrt fp onset
         if nargin >= 3 && ~isempty(syncTimes)
            
            numTrials = size(syncTimes,1);
            analog = struct(     ...
               'name',         {tags}, ... % 1xn" cell array of strings
               'acquire_rate', [],   ... % 1xn array of #'s, in Hz
               'store_rate',   round(1/median(diff(rawData(:,1)))),   ... % 1xn" array of #'s, in Hz
               'error',        {{}}, ... % mx1  array of error messages
               'data',         {cell(numTrials,1)});      % mxn" cell array
            
            % Get list of local start times
            localTrialStartTimes = [syncTimes(:,1); inf];
            
            for tt = 1:numTrials
               
               % Get gaze data
               Lgaze = rawData(:,eti) >= localTrialStartTimes(tt) & ...
                  rawData(:,eti) < localTrialStartTimes(tt+1);
               
               % Put eye data in order: time, x, y, confidence, pupil
               analog.data{tt} = rawData(Lgaze, [eti exi eyi eci epi]);
               
               % Calibrate timestamps to local time
               analog.data{tt}(:,1) = analog.data{tt}(:,1) - syncTimes(tt,1) - ...
                  syncTimes(tt,3);
            end
         end
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
         
         % get a keyboard, if not given
         if isempty(self.calibrationUI)
            if isa(self, 'dotsReadableEyeMouseSimulator')
               
               % special case of mouse simulator
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
         while ~isempty(self.calibrationUI.getNextEvent())
         end
         self.calibrationUI.flushData();
         
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
            eyeCue                      = dotsDrawableTargets();
            eyeCue.width                = 0.5;
            eyeCue.height               = 0.5;
            eyeCue.isColorByVertexGroup = true;
            self.calibration.eyeEnsemble = dotsDrawable.makeEnsemble( ...
               'eyeEnsemble', {eyeCue});
         end
         
         % Default no error
         status = 0;
         
         % Check for calibration/drift correction mode
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
                     
                     if self.calibration.showEye
                        disp('space or s to show eye, r to repeat calibration, q to finish')
                     else
                        disp('s to show eye, r to repeat calibration, space or q to finish')
                     end
                     
                     % Wait for keyboard input
                     [didHappen, ~, ~, ~, nextEvent] = dotsReadable.waitForEvent( ...
                        self.calibrationUI, [], self.calibration.queryTimeout);
                     
                     % Made it through timeout, just continue. Otherwise
                     % wait for key up
                     if ~didHappen
                        nextEvent = 'accept';
                     else
                        dotsReadable.waitForEvent(self.calibrationUI, ...
                           [], self.gazeCalibration.queryTimeout);
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
         
         % Collect transformed x,y data
         gazeXY = self.collectXY(self.calibration.offsetN, true);
         
         % Possibly hide target
         if showTarget
            dotsTheScreen.blankScreen();
         end
         
         % Now add the offsets if within tolerance, and flush the queue
         % of the older, uncalibrated samples
         % var(gazeXY)
         if all(var(gazeXY) < self.calibration.offsetVarTolerance)
            self.setEyeCalibration(self.gazeCalibration.xyOffset + ...
               currentXY - median(gazeXY), [], []);
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
         fi = 1/self.helpers.screenEnsemble.getObjectProperty('windowFrameRate', 1);
         
         % Loop until spacebar
         while ~strcmp(self.calibrationUI.getNextEvent(), 'accept')
            
            % Get all new events
            tic;
            while toc < fi - 0.004 % leave some flip time
               
               % Read the new data
               self.read();
               
               % rotate buffer
               if self.time > lastTime
                  lastTime            = self.time;
                  xyData(1:end-1,1:2) = xyData(2:end,1:2);
                  xyData(end,1:2)     = [self.x self.y];
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
         
         % blank the screen
         dotsTheScreen.blankScreen();
      end
      
      % calibrateNow
      %
      % Calibrate with respect to screen coordinates
      % Can be overloaded
      function status = calibrateNow(self)
         
         % For debugging
         % fig = figure;
         % cla reset; hold on;
         
         % get the ensemble
         targetEnsemble = self.calibration.targetEnsemble;
         
         % Show a help message
         if self.calibration.showMessage
            dotsDrawableText.drawEnsemble(dotsDrawableText.makeEnsemble( ...
               'textEnsemble', 1, []), {'Please look at each object'}, 3, 0.3);
         end
         
         % Set up matrices to present cues and collect fixation data
         targetXY = [ ...
            -self.calibration.fpX  self.calibration.fpY;
            self.calibration.fpX   self.calibration.fpY;
            self.calibration.fpX  -self.calibration.fpY;
            -self.calibration.fpX -self.calibration.fpY];
         numFixations = size(targetXY, 1);
         
         % show it once; delay sometimes needed for graphics to initialize
         pause(0.5);
         targetEnsemble.setObjectProperty('xCenter', targetXY(1, [1 1]));
         targetEnsemble.setObjectProperty('yCenter', targetXY(1, [2 2]));
         targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
         pause(0.5);
         
         % Variables to collect data and check for success
         gazeXY = nans(numFixations, 2);
         checkCalibrationCounter = 1;
         isCalibrated = false;
         
         while ~isCalibrated && ...
               checkCalibrationCounter < self.calibration.numberTries
            
            % Loop through each target to get eye position samples
            for ii = 1:numFixations
               
               % Show the fixation point
               targetEnsemble.setObjectProperty('xCenter', targetXY(ii,[1 1]));
               targetEnsemble.setObjectProperty('yCenter', targetXY(ii,[2 2]));
               targetEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               
               % Wait for fixation
               pause(0.3);
               
               % flush the eye data
               self.flushData();
               
               % Try multiple times to get a good fixation
               isSampled = false;
               checkFixationCounter = 1;
               while ~isSampled && ...
                     checkFixationCounter < ...
                     self.calibration.numberTries*numFixations
                  
                  % Start the device
                  self.startTrialDevice();
                  pause(0.1);
                  
                  % Collect samples
                  gazeRawXY = collectXY(self, self.calibration.fullN);
                  
                  % Finish the device
                  self.finishTrialDevice();
                  
                  % disp(var(gazeRawXY))
                  % disp(self.calibration.varTolerance)
                  
                  % Check tolerance
                  if all(var(gazeRawXY) < self.calibration.varTolerance)
                     
                     % Good! Save median and go on to next sample
                     gazeXY(ii,:) = nanmedian(gazeRawXY);
                     isSampled = true;
                     % plot(gazeRawXY(:,1), gazeRawXY(:,2), 'kx');
                  else
                     
                     % Update the counter
                     checkFixationCounter = checkFixationCounter + 1;
                  end
               end
               
               % Check for failure
               if ~isSampled
                  status = 1;
                  return
               end
               
               % Briefly blank the screen
               dotsTheScreen.blankScreen();
               
               % wait a moment
               pause(0.5);
            end
            
            % Get vectors connecting each point
            diffTargetXY    = diff([targetXY; targetXY(1,:)]);
            lenDiffTargetXY = sqrt(sum(diffTargetXY.^2,2));
            diffGazeXY      = diff([gazeXY; gazeXY(1,:)]);
            lenDiffGazeXY   = sqrt(sum(diffGazeXY.^2,2));
            
            % Select x,y directions
            Lx = diffTargetXY(:,1)~=0;
            Ly = diffTargetXY(:,2)~=0;
            
            % Calculate average x,y scaling
            xyScaleVals = [ ...
               mean(lenDiffTargetXY(Lx,:) ./ lenDiffGazeXY(Lx,:)) ...
               mean(lenDiffTargetXY(Ly,:) ./ lenDiffGazeXY(Ly,:))];
            
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
            
            % Check tolerance
            transformedData = ...
               [xyScaleVals(1).*gazeXY(:,1) xyScaleVals(2).*gazeXY(:,2)] * ...
               rotationVals + repmat(xyOffsetVals, size(gazeXY,1), 1);
            
            % For debugging
            %             plot(targetXY(:,1), targetXY(:,2), 'ro');
            %             plot(gazeXY(:,1), gazeXY(:,2), 'go');
            %             plot(transformedData(:,1), transformedData(:,2), 'ko');
            %             disp(sqrt(sum((targetXY-transformedData).^2,2)))
            %             r = input('next')
            %             cla reset; hold on;
            
            % check for accuracy
            if all(sqrt(sum((targetXY-transformedData).^2,2)) < ...
                  self.calibration.transformTolerance)
               
               % Done!
               self.setEyeCalibration(xyOffsetVals, xyScaleVals, rotationVals);
               isCalibrated = true;
            else
               
               % Trying again
               disp(sqrt(sum((targetXY-transformedData).^2,2)))
               checkCalibrationCounter = checkCalibrationCounter + 1;
            end
         end
         
         % Check for faliure
         status = double(~isCalibrated);
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
      
      % Collect xy data
      function xy = collectXY(self, N, doTransform)
         
         xy = nans(N, 2);
         
         if nargin >= 3 && doTransform
            for ii = 1:N
               newData = self.transformRawData(self.readRawEyeData());
               xy(ii,:) = newData([self.xID, self.yID], 2)';
            end
         else
            for ii = 1:N
               newData = self.readRawEyeData();
               xy(ii,:) = newData([self.xID, self.yID], 2)';
            end
         end
         
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
         
         % Make array of calibration timestamps ... remember these are in local time
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
   end
end