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
      
      % how to offset raw pupil data, before scaling
      pupilOffset = 0;
      
      % how to scale raw pupil data, after ofsetting
      pupilScale = 1;
      
      % the current pupil size, offset and scaled
      pupil;
      
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
      
      % IP/port information for showing calibration graphics on remote
      % screen (see calibrateEyeSnowDots, below). Cell array of either:
      %  {false} for local mode, or
      %  {true <local IP> <local port> <remote IP> <remote port>}
      ensembleRemoteInfo = {false};
      
      % Flag to show eye position and gaze window in a matlab fig
      showGazeMonitor = false;
      
      % Number of samples to collect for calibration offset
      offsetN = 50;
      
      % Number of samples to collect for full calibation
      calibrationN = 500;
      
      % x offset for calibration target grid
      calibrationFPX = 10;
      
      % y offset for calibration target grid
      calibrationFPY = 5;
      
      % Size of calibration target
      calibrationFPSize = 2;
   end
   
   properties (SetAccess = protected)
      
      % how to offset raw x,y gaze data, before scaling
      xyOffset = [0 0];
      
      % how to scale raw x,y gaze data, after ofsetting
      xyScale = [1 1];
      
      % how to rotate x,y gaze data
      rotation = [1 0; 0 1];
      
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
      
      % Properties used for the gaze monitor window      
      % gaze monitor axies
      gazeMonitorAxes = [];
      
      % axis limits
      gazeMonitorLim = 20;
      
      % handle to the line object used to plot the eye position
      gazeMonitorDataHandle = [];
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
         name = varargin{1}
         
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
         if self.showGazeMonitor
            self.updateGazeMonitorWindow(index);
         end
      end
      
      % Activate gaze windows
      function activateCompoundEvents(self)
         
         % Deactivate all of the gaze windows
         [self.gazeEvents.isActive] = deal(true);
         
         % Hide the gazeMonitor windows
         if self.showGazeMonitor
            for ii = 1:length(self.gazeEvents)
               self.updateGazeMonitorWindow(ii);
            end
         end
      end
      
      % De-activate gaze windows
      function deactivateCompoundEvents(self)
         
         % Deactivate all of the gaze windows
         [self.gazeEvents.isActive] = deal(false);
         
         % Hide the gazeMonitor windows
         if self.showGazeMonitor
            for ii = 1:length(self.gazeEvents)
               self.updateGazeMonitorWindow(ii);
            end
         end
      end
      
      % Open the gaze monitor
      % 
      %  Open the window and set the showGazeMonitor flag to true
      function openGazeMonitor(self)
         
         % Possibly initialize the gaze monitor
         if isempty(self.gazeMonitorAxes)
            
            % Use the current figure
            % figure;
            clf;
            
            % Use the current axes
            self.gazeMonitorAxes = gca; 
            
            % Make sure hold is on so multiple windows and gaze 
            %  position can be shown together
            hold on;
            
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
               'FontSize', 14)
            xlabel('Horizontal eye position (deg)')
            ylabel('Vertical eye position (deg)')
            
            % add handle to gaze data (an 'x' showing the current gaze
            % position)
            self.gazeMonitorDataHandle = line(0, 0, ...
               'Color',       'r', ...
               'Marker',      'x', ...
               'MarkerSize',  12,  ...
               'LineWidth',   3);
         end
         
         % Monitor is on
         self.showGazeMonitor = true;         
      end
      
      % Close the gaze monitor
      %
      % For now just turn the flag off, but don't do anything else
      function closeGazeMonitor(self)

         % Monitor is off
         self.showGazeMonitor = false;
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
      %   'recenter'
      %   [current_gaze_x current_gaze_y]
      function calibrateDevice(self, varargin)
         
         % Check for special case of recentering
         if nargin > 1 && strcmp(varargin{1}, 'recenter')
            if nargin > 2 || ~isempty(varargin{2})
               currentXY = varargin{2};
            else
               currentXY = [0 0];
            end
            
            % Collect transformed x,y data
            gazeXY = nans(self.offsetN, 2);
            for ii = 1:self.offsetN
               dataMatrix = self.transformRawData(self.readRawEyeData());
               gazeXY(ii,:) = dataMatrix([self.xID, self.yID], 2)';
            end
 
            % Now add the offsets
            self.xyOffset = self.xyOffset + median(gazeXY) - currentXY;
            return
         end
         
         % Otherwise do full calibration
         % Make a drawing ensemble for the calibration target
         calibrationEnsemble = dotsEnsembleUtilities.makeEnsemble( ...
            'calibrationEnsemble',self.ensembleRemoteInfo{:});
         
         % Start with blank screen
         calibrationEnsemble.callObjectMethod(@dotsDrawable.blankScreen, {}, [], true);
        
         % Show instructions, then blank the screen
         text   = dotsDrawableText();
         text.string = 'Look at each object and try not to blink';
         index = calibrationEnsemble.addObject(text);
         calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
         pause(3.0);
         calibrationEnsemble.callObjectMethod(@dotsDrawable.blankScreen, {}, [], true);
         calibrationEnsemble.removeObject(index);
                  
         % Generate Fixation target (cross)
         %
         % We will create a single drawable object to represent the fixation cue.
         % Then, we simply adjust the location of the cue each time we present it.
         fixationCue = dotsDrawableTargets();
         fixationCue.width  = [1 0.1] * self.calibrationFPSize;
         fixationCue.height = [0.1 1] * self.calibrationFPSize;
         calibrationEnsemble.addObject(fixationCue);
         
         self.calibrationFPX    = 10;
         self.calibrationFPY    = 5;

         % Set up matrices to present cues and collect fixation data
         targetXY = [ ...
            -self.calibrationFPX  self.calibrationFPY;
            self.calibrationFPX  self.calibrationFPY;
            self.calibrationFPX -self.calibrationFPY;
            -self.calibrationFPX -self.calibrationFPY];
         numFixations = size(targetXY, 1);
         
         % Loop through the fixations and collect eye position data
         gazeRawXY = nans(self.calibrationN, 2);
         gazeXY = nans(numFixations, 2);
         for ii = 1:numFixations
            
            % Show the fixation point
            calibrationEnsemble.setObjectProperty('xCenter', [targetXY(ii,1) targetXY(ii,1)]);
            calibrationEnsemble.setObjectProperty('yCenter', [targetXY(ii,2) targetXY(ii,2)]);
            calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            
            % Wait for fixation
            pause(0.4);
            
            % flush the eye data
            self.flushData();
            
            % Collect a bunch of samples
            for jj = 1:self.calibrationN
               dataMatrix = self.readRawEyeData();
               gazeRawXY(jj,:) = dataMatrix([self.xID, self.yID], 2)';
            end
            
            % Get median values
            gazeXY(:,2) = nanmedian(gazeRawXY);
            
            % Briefly blank the screen
            calibrationEnsemble.callObjectMethod(@dotsDrawable.blankScreen, {}, [], true);
            
            % wait a moment
            pause(0.25);
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
         self.xyScale = [ ...
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
         self.rotation = [cos(ang) -sin(ang); sin(ang) cos(ang)];
         
         % Calculate average x,y offset
         self.xyOffset = mean(targetXY -  ...
            [self.xScale.*gazeXY(:,1) self.yScale.*gazeXY(:,2)] * self.rotation);
      end
      
      % Close the components and release the resources.
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
         
         % update gaze window data by computing distance of gaze
         %  to center of each window
         if ~isempty(self.gazeEvents)
            
            % Get Logical array of isActive flags
            LactiveFlags = [self.gazeEvents.isActive];
            
            % Check for active gazeWindows
            if ~any(LactiveFlags)
               return
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
            
            % disp(gazeData(end,2:3))
            % Possibly update monitor window
            if self.self.showGazeMonitor
               set(self.gazeMonitorDataHandle, ...
                  'XData', gazeData(end,2), 'YData', gazeData(end,3));
               drawnow;
            end
            
            % Save the current gaze
            self.x = gazeData(end,2);
            self.y = gazeData(end,3);
            
            % Now loop through each active gaze event and update
            for ii = find(LactiveFlags)
               
               % Get the gaze event struct, for convenience
               ev = self.gazeEvents(ii);
               % disp(sprintf('checking <%s>', ev.name))
               
               % Calcuate number of samples to add to the buffer
               bufLen = size(ev.sampleBuffer,1);
               numSamplesToAdd = min(bufLen, numSamples);
               
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
               
               % Check for event:
               %  1. current sample is in acceptance window
               %  2. at least one other sample is in acceptance window
               %  3. earlist sample in acceptance window was at least
               %     historyLength in the past
               %  4. no intervening samples were outside window
               if ev.isInverted
                  Lgood = ev.sampleBuffer(:,2) > ev.windowSize;
               else
                  Lgood = ev.sampleBuffer(:,2) <= ev.windowSize;
               end
               if Lgood(end) && any(Lgood(1:end-1))
                  fg = find(Lgood,1);
                  if (ev.sampleBuffer(fg,1) <= ...
                        (ev.sampleBuffer(end,1) - ev.windowDur)) %&& ...
                     %  (all(Lgood(fg:end) | ~isfinite(ev.sampleBuffer(fg:end,1))))
                     
                     % Add the event to the data stream
                     newData = cat(1, newData, ...
                        [ev.ID ev.sampleBuffer(fg,[2 1])]);
                  end
               end
               
               % Save the event struct back in the object
               self.gazeEvents(ii)=ev;
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
         self.xScale = self.xyRect(3)/self.inputRect(3);
         self.xOffset = ...
            (self.xyRect(1)/self.xScale) - self.inputRect(1);
         self.yScale = self.xyRect(4)/self.inputRect(4);
         self.yOffset = ...
            (self.xyRect(2)/self.yScale) - self.inputRect(2);
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
            
            % Draw the circle now
            th = (0:pi/50:2*pi)';
            set(self.gazeEvents(index).gazeWindowHandle, ...
               'XData', ...
               self.gazeEvents(index).windowSize * cos(th) + ...
               self.gazeEvents(index).centerXY(1), ...
               'YData', ...
               self.gazeEvents(index).windowSize * sin(th) + ...
               self.gazeEvents(index).centerXY(2));
            drawnow;
         else
            
            % Remove the circle from the gaze monitor
            set(self.gazeEvents(index).gazeWindowHandle, ...
               'XData', 0, 'YData', 0);
            drawnow;
         end
      end
   end
end