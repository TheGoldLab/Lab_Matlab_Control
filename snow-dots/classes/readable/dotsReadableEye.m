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
   % might be more natural, such as degrees of visual angle.  It uses
   % inputRect to impose a coordinate system on the raw data and presents
   % data in a coordinate sytem relative to xyRect.
   % @details
   % inputRect and xyRect should have the form [x y width height].  Both
   % rectangles should describe the same region, such as part of a
   % calibration pattern.  inputRect should use units that are native to
   % the eye tracker.  These units will be "divided out".  xyRect should
   % be in units that will be useful to experiment code, such as degrees
   % of visual angle.
   % @details
   % The width or height of either rectangle may negative, in order to
   % flip the corresponding axis.  If both rectangles are equal, no unit
   % transformation will happen.
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
      
      % rectangle desctibing eye tracker device coordinates ([x y w h])
      % @details
      % inputRect describes a rectangular region of interest using the
      % eye tracker's native coordinate system.  dotsReadableEye
      % transforms raw position data <b>out of</b> these coordinates.
      inputRect = [0 0 1 1];
      
      % rectangle desctibing user-defined coordinates ([x y w h])
      % @details
      % xyRect describes a rectangular region of interest using
      % arbitrary, user-defined coordinates.  dotsReadableEye transforms
      % raw position data <b>into</b> these coordinates.
      xyRect = [0 0 1 1];
      
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
      
      % topsEnsemble (or dotsClientEnsemble) object holding the screen
      % object
      screenEnsemble = [];
      
      % axis limits
      gazeMonitorLim = 20;
      
      % Number of samples to collect for calibration offset
      offsetCalibrationN = 30;
      
      % Number of samples to collect for full calibation
      fullCalibrationN = 100;
      
      % x offset for calibration target grid
      calibrationFPX = 10;
      
      % y offset for calibration target grid
      calibrationFPY = 5;
      
      % Size of calibration target
      calibrationFPSize = 2;
      
      % Tolerance for using calibration values -- determined by
      % trial-and-error
      calibrationVarTolerance = 0.0001;
      
      % Tolerance for using calibration values -- determined by
      % trial-and-error
      OffsetVarTolerance = 2.0;
      
      % Tolerance for using calibration values -- determined by
      % trial-and-error
      calibrationTransformTolerance = 4.0;
      
      % number of times to try calibrating before giving a message if it
      % keeps failing (not within tolerances
      numberCalibrationTries = 5;
   end
   
   properties (SetAccess = protected)
      
      % how to offset raw x,y gaze data, before scaling
      xyOffset = [0 0];
      
      % how to scale raw x,y gaze data, after ofsetting
      xyScale = [1 1];
      
      % how to rotate x,y gaze data
      rotation = [1 0; 0 1];
      
      % how to offset raw pupil data, before scaling
      pupilOffset = 0;
      
      % how to scale raw pupil data, after ofsetting
      pupilScale = 1;
      
      % integer identifier for x-position component
      xID = 1;
      
      % integer identifier for y-position data
      yID = 2;
      
      % integer identifier for pupil size data
      pupilID = 3;
      
      % Array of gazeWindow event structures
      gazeEvents = [];
      
      % target for calibration
      calibrationEnsemble = [];
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
   end
   
   methods
      
      % Constructor takes no arguments.
      function self = dotsReadableEye()
         self = self@dotsReadable();
      end
      
      % Connect to eye tracker and prepare coordinate transforms.
      function initialize(self)
         self.initialize@dotsReadable();
         self.setupCoordinateRectTransform();
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
      
      % Overloaded defineCompoundEvent function
      %
      % For Eye trackers, this is a gaze window that checks whether
      %   gaze (x and y coordinates, which is why it must
      %   be defined as a "compound" event) falls into or out of a
      %   circular window.
      %
      % Arguments are either cell arrays of multiple windows that each
      %   include the following arguments, or just subsets of the following
      %   arguments (first is required, the subsequent property/value
      %   pairs are optional):
      %
      %  name is a unique string identifier
      %  eventName   ... Name of event used by dotsReadable.getNextEvent
      %  centerXY    ... x,y coordinates of center of gaze window
      %  channelsXY  ... Indices of data channels for x,y position
      %  windowSize  ... Diameter of circular gaze window
      %  windowDur   ... How long eye must be in window (msec) for event
      %  isInverted  ... If true, checking for *out* of window
      %  isActive    ... Flag indicating if this event is currently active
      function defineCompoundEvent(self, varargin)
         
         % This shouldn't happen
         if nargin < 2
            return;
         end
         
         % If multiple definitions given, loop through one at a time
         if iscell(varargin{1})
            for ii = 1:nargin-1
               defineCompoundEvent(self, varargin{ii}{:});
            end
            return
         end
         
         % first argument is the name
         name = varargin{1};
         
         % check if it already exists
         if isempty(self.gazeEvents) || ~any(strcmp(name, {self.gazeEvents.name}))
            
            % Add window as "component"
            numComponents = numel(self.components);
            ID = numComponents + 1;
            self.components(ID).ID = ID;
            
            % Add the new gaze window struct to the end of the array
            %   Buffer is [timestamp distance_from_center_of_window]
            index = length(self.gazeEvents) + 1;
            self.gazeEvents = cat(1, self.gazeEvents, struct( ...
               'name',             name, ...
               'ID',               ID, ...
               'eventName',        [], ...
               'channelsXY',       [self.xID self.yID], ...
               'centerXY',         [0 0], ...
               'windowSize',       3, ...
               'windowDur',        0.2, ...
               'isInverted',       false, ...
               'isActive',         false, ...
               'sampleBuffer',     [], ...
               'gazeWindowHandle', []));
         else
            
            % Use existing gaze window struct
            index = find(strcmp(name, {self.gazeEvents.name}));
         end
         
         % Parse args
         for ii=2:2:nargin-2
            self.gazeEvents(index).(varargin{ii}) = varargin{ii+1};
         end
         
         % Check/clear sample buffer
         len = self.gazeEvents(index).windowDur*self.sampleFrequency+2;
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
         eventName = self.gazeEvents(index).eventName;
         eventID = self.gazeEvents(index).ID;
         self.components(eventID).name = eventName;
         self.defineEvent(eventID, eventName, -inf, inf, false, ...
            self.gazeEvents(index).isActive);
         
         % Update the gaze monitor data -- x,y positions of circle
         if self.useGUI
            self.updateGazeMonitorWindow(index);
         end
      end
      
      % Activate gaze windows
      function activateCompoundEvents(self)
         
         % Activate all of the gaze windows
         if ~isempty(self.gazeEvents)
            [self.gazeEvents.isActive] = deal(true);
         end
         
         % Show the gazeMonitor windows
         if self.useGUI
            for ii = 1:length(self.gazeEvents)
               self.updateGazeMonitorWindow(ii);
            end
         end
      end
      
      % De-activate gaze windows
      function deactivateCompoundEvents(self)
         
         % Deactivate all of the gaze windows
         if ~isempty(self.gazeEvents)
            [self.gazeEvents.isActive] = deal(false);
         end
         
         % Hide the gazeMonitor windows
         if self.useGUI
            for ii = 1:length(self.gazeEvents)
               self.updateGazeMonitorWindow(ii);
            end
         end
      end
      
      % Delete all compoundEvents
      function clearCompoundEvents(self)
         
         % Deactivate the current gaze events so the monitor window is
         % appropriately cleared
         self.deactivateCompoundEvents;
         
         % Now clear them
         self.gazeEvents = [];
         
         % Now clear the associated events
         self.clearEvents();
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
         lims = [-self.gazeMonitorLim self.gazeMonitorLim];
         tics = -self.gazeMonitorLim:5:self.gazeMonitorLim;
         
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
      
      % Possibly buffer and recenter gaze
      %
      % Arguments:
      %  useBuffer   ... flag to stop/start buffering
      %  recenter    ... if true, recenter to [0 0]
      %                  or use given values
      function resetGaze(self, useBuffer, recenter)
         
         % Conditionally set flag
         if nargin > 1 && ~isempty(useBuffer)
            self.bufferGazeData = useBuffer;
         end
         
         % Conditionally re-center gaze (drift correct)
         if nargin > 2 && ~isempty(recenter)
            if islogical(recenter) && recenter
               self.calibrate('d')
            elseif isnumeric(recenter) && length(recenter)==2
               self.calibrate('d', recenter);
            end
         end
         
         set(self.gazeMonitorBufferedDataHandle, ...
            'XData', [], ...
            'YData', []);
      end
      
      % Utilities for changing calibration offsets (e.g., via GUI)
      function incrementCalibrationOffsetX(self, increment)
         self.setEyeCalibration(self.xyOffset + [increment 0], [], []);
      end
      
      function incrementCalibrationOffsetY(self, increment)
         self.setEyeCalibration(self.xyOffset + [0 increment], [], []);
      end
      
      % Set the calibration parameters and dump to the data log.
      %  This is public in case you want to set these by hand for some
      %  reason
      function setEyeCalibration(self, xyOffsets, xyScales, rotations)
         
         % Conditionally set the inputs..note that all arguments must
         %  be given, but use [] as flag not to change
         if ~isempty(xyOffsets)
            self.xyOffset = xyOffsets;
         end
         if ~isempty(xyScales)
            self.xyScale = xyScales;
         end
         if ~isempty(rotations)
            self.rotation = rotations;
         end
         
         % Save it to the log
         topsDataLog.logDataInGroup( ...
            {feval(self.clockFunction) self.xyOffset, self.xyScale, self.rotation}, ...
            'dotsReadableEye calibration');
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
      %   1: mode flag: 'c' for calibrate, 'd' for drift correction
      %   2: optional x,y values of current gaze for drift correcton
      %
      % Returns:
      %  status = 0 if calibrated within tolerance, 1 if error
      %
      function status = calibrateDevice(self, mode, varargin)
         
         if nargin < 2 || isempty(mode)
            mode = 'c';
         end
         
         % Check for calibration/drift correction mode
         switch mode
            case {'d' 'D'}
               
               % Drift correction
               status = self.driftCorrectNow(varargin{:});
               
            otherwise % case {'c' 'C'}
               
               % Calibration
               status = self.calibrateNow();
         end
      end
      
      % driftCorrectNow
      %
      % Do drift correction. Optional argument is x,y location of
      %  current gaze
      function status = driftCorrectNow(self, currentXY)
         
         if nargin < 2 || isempty(currentXY)
            currentXY = [0 0];
         end
         
         % Collect transformed x,y data
         gazeXY = nans(self.offsetCalibrationN, 2);
         for ii = 1:self.offsetCalibrationN
            dataMatrix = self.transformRawData(self.readRawEyeData());
            gazeXY(ii,:) = dataMatrix([self.xID, self.yID], 2)';
         end
         
         % Now add the offsets if within tolerance, and flush the queue
         % of the older, uncalibrated samples
         % var(gazeXY)
         if all(var(gazeXY) < self.OffsetVarTolerance)
            self.setEyeCalibration( ...
               self.xyOffset + currentXY - median(gazeXY), [], []);
            self.flushData();
         else
            disp('dotsReadableEye calibration recenter failed')
         end
         
         % all is good
         status = 0;
      end
      
      % calibrateNow
      %
      % Calibrate with respect to screen coordinates
      function status = calibrateNow(self)
         
         % For debugging
         % fig = figure;
         % cla reset; hold on;
         
         % Generate Fixation target (cross)
         %
         % We will create a single drawable object to represent the fixation cue.
         % Then, we simply adjust the location of the cue each time we present it.
         if isempty(self.calibrationEnsemble)
            fixationCue = dotsDrawableTargets();
            fixationCue.width  = [1 0.1] * self.calibrationFPSize;
            fixationCue.height = [0.1 1] * self.calibrationFPSize;
            self.calibrationEnsemble = makeDrawableEnsemble(...
               'calibrationEnsemble', {fixationCue}, self.screenEnsemble);
         end
         
         % Set up matrices to present cues and collect fixation data
         targetXY = [ ...
            -self.calibrationFPX  self.calibrationFPY;
            self.calibrationFPX  self.calibrationFPY;
            self.calibrationFPX -self.calibrationFPY;
            -self.calibrationFPX -self.calibrationFPY];
         numFixations = size(targetXY, 1);
         
         % show it once, after a delay sometimes needed for graphics to
         % initialize
         pause(0.7);
         self.calibrationEnsemble.setObjectProperty('xCenter', targetXY(1,[1 1]));
         self.calibrationEnsemble.setObjectProperty('yCenter', targetXY(1,[2 2]));
         self.calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
         pause(0.5);
         
         % Variables to check for success
         gazeRawXY = nans(self.fullCalibrationN, 2);
         gazeXY = nans(numFixations, 2);
         checkCalibrationCounter = 1;
         isCalibrated = false;
         
         while ~isCalibrated && ...
               checkCalibrationCounter < self.numberCalibrationTries
            
            % Loop through each target to get eye position samples
            gazeXY(:) = nan;
            for ii = 1:numFixations
               
               % Show the fixation point
               self.calibrationEnsemble.setObjectProperty('xCenter', targetXY(ii,[1 1]));
               self.calibrationEnsemble.setObjectProperty('yCenter', targetXY(ii,[2 2]));
               self.calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
               
               % Wait for fixation
               pause(0.4);
               
               % flush the eye data
               self.flushData();
               
               % Try multiple times to get a good fixation
               isSampled = false;
               checkFixationCounter = 1;
               while ~isSampled && ...
                     checkFixationCounter < ...
                     self.numberCalibrationTries*numFixations
                  
                  % Collect a bunch of samples
                  for jj = 1:self.fullCalibrationN
                     dataMatrix = self.readRawEyeData();
                     gazeRawXY(jj,:) = dataMatrix([self.xID, self.yID], 2)';
                  end
                  
                  % Check tolerance
                  if all(var(gazeRawXY) < self.calibrationVarTolerance)
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
               self.calibrationEnsemble.callObjectMethod( ...
                  @dotsDrawable.blankScreen, {}, [], true);
               
               % wait a moment
               pause(0.7);
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
                  self.calibrationTransformTolerance)
               
               % Done!
               self.setEyeCalibration(xyOffsetVals, xyScaleVals, rotationVals);
               isCalibrated = true;
            else
               disp(sqrt(sum((targetXY-transformedData).^2,2)))
               checkCalibrationCounter = checkCalibrationCounter + 1;
            end
         end
         
         % Check for faliure
         status = double(~isCalibrated);
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
         
         % get new data
         rawData = self.transformRawData(self.readRawEyeData());
         
         % check whether or not we pass along all the raw data
         %  or just the events
         if self.readEventsOnly
            newData = [];
         else
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
               
               % Looking for first/last samples indide window
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
      
      % Read and format raw eye tracker data (for subclasses).
      % @details
      % Subclasses must redefine readRawEyeData() to read and return raw
      % data from the eye tracker.  readRawEyeData() should use xID, yID
      % and pupilID to identify x, y, and pupil component data.  Data
      % using these IDs will be transformed automatically into
      % user-defined coordinates.
      function newData = readRawEyeData(self)
         newData = zeros(0,3);
      end
      
      % Replace x, y, and pupil data with transformed data.
      % @param newData nx3 double matrix of data from readRawEyeData()
      % @details
      % Transforms raw data into user-defined coordinates.  Only data
      % with conponent ID xID, yID, and pupilID will be transformed.
      % @details
      % Updates the x, y and pupil properties with the latest,
      % transformed values.  Assumes data for each component are sorted
      % with the most recent value last.
      function newData = transformRawData(self, newData)
         
         % Logical arrays of x,y gaze data
         Lx = newData(:,1) == self.xID;
         Ly = newData(:,1) == self.yID;
         
         % Could check if same number of x,y samples but that should always
         % be true
         if any(Lx)
            
            % Scale, rotate, then offset
            transformedData = ...
               [self.xyScale(1).*newData(Lx,2) self.xyScale(2).*newData(Ly,2)] * ...
               self.rotation + repmat(self.xyOffset, sum(Lx), 1);
            
            % Save the transformed x value(s)
            newData(Lx,2) = transformedData(:,1);
            self.x = transformedData(end,1);
            
            % Save the transformed y value(s)
            newData(Ly,2) = transformedData(:,2);
            self.y = transformedData(end,2);
         end
         
         % Transform the pupil
         pupilSelector = newData(:,1) == self.pupilID;
         if any(pupilSelector)
            transPupil = self.pupilScale ...
               *(self.pupilOffset + newData(pupilSelector,2));
            newData(pupilSelector,2) = transPupil;
            self.pupil = transPupil(end);
         end
      end
      
      % Prepare the transform from inputRect to xyRect coordinates.
      % @details
      % Combines the transforms out of inputRect coordinates and into
      % xyRect coordinates into a single transform to be applied to data
      % during appendData().
      function setupCoordinateRectTransform(self)
         self.xyScale = [ ...
             self.xyRect(3)/self.inputRect(3), ...
             self.xyRect(4)/self.inputRect(4)];
             
         self.xyOffset = [ ...
            (self.xyRect(1)/self.xyScale(1)) - self.inputRect(1), ...
            (self.xyRect(2)/self.xyScale(2)) - self.inputRect(2)];
      end
   end
   
   % These methods are called only by local functions
   methods (Access = private)
      
      % Set up the gaze monitor and update the gazeWindow (circle)
      % associted with the given index
      function updateGazeMonitorWindow(self, index)
         
         % Possibly make a handle to the line object that we'll use to
         % draw the gaze window circle
         if isempty(self.gazeEvents(index).gazeWindowHandle)
            axes(self.gazeMonitorAxes);
            self.gazeEvents(index).gazeWindowHandle = line(0,0);
         end
         
         % If active, update the data to draw the circle
         if self.gazeEvents(index).isActive
            
            % Draw the circle
            th = (0:pi/50:2*pi)';
            if self.gazeEvents(index).isInverted
               lineStyle = ':';
            else
               lineStyle = '-';
            end
            set(self.gazeEvents(index).gazeWindowHandle, ...
               'XData', ...
               self.gazeEvents(index).windowSize * cos(th) + ...
               self.gazeEvents(index).centerXY(1), ...
               'YData', ...
               self.gazeEvents(index).windowSize * sin(th) + ...
               self.gazeEvents(index).centerXY(2), ...
               'LineStyle', ...
               lineStyle);
         else
            
            % Remove the circle from the gaze monitor
            set(self.gazeEvents(index).gazeWindowHandle, ...
               'XData', 0, 'YData', 0);
         end
         
         % update the plot
         drawnow;
      end
   end
   
   methods (Static)
      
      % Utility for using a topsDataLog 'dotsReadableEye calibration'
      %  item to calibrate gaze for a single chunk of data
      %
      %  calibrationCell is the cell array stored in the topsDataLog
      %     in setEyeCalibration, above.
      %  cell contents:
      %     1. timestamp
      %     2. xyOffset
      %     3. xyScale
      %     4. rotation matrix
      function calibratedXY = calibrateGaze(rawXY, calibrationCell)
         
         numSamples = size(rawXY, 1);
         if numSamples > 0
            
            % Scale, rotate, then offset
            calibratedXY = [ ...
               calibrationCell{3}(1).*rawXY(:,1) ...
               calibrationCell{3}(2).*rawXY(:,2)] * ...
               calibrationCell{4} + repmat(calibrationCell{2}, numSamples, 1);
         else
            calibratedXY = [];
         end
      end
      
      % Utility for calibrating gaze using an array of structures
      % containing 'dotsReadableEye calibration' items
      %
      % Raw values columns are time, gaze_x, gaze_y
      function calibratedValues = calibrateGazeSets(rawValues, calibrationSets)
         
         % Make array of calibration timestamps ... remember these are in local time
         calibrationCell = cat(1, calibrationSets.item);
         calibrationTimes = cat(1, calibrationCell{:,1}, inf);
         
         % Calibrate gaze, in chunks
         for cc = 1:size(calibrationTimes)-1
            
            % get relevant samples
            Lcal = rawValues(:,1) >= calibrationTimes(cc) & ...
               rawValues(:,1) < calibrationTimes(cc+1);
            rawValues(Lcal,2:3) = dotsReadableEye.calibrateGaze( ...
               rawValues(Lcal,2:3), calibrationCell(cc,:));
         end
         calibratedValues = rawValues;
      end
   end
end