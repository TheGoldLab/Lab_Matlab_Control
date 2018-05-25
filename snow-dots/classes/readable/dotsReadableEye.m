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
      
      % Calibration parameters ... number of samples, then X,Y,size of
      % fixation point
      calibrationN      = 500;
      calibrationFPX    = 10;
      calibrationFPY    = 5;
      calibrationFPSize = 1;
   end
   
   properties (SetAccess = protected)
      % how to offset raw x data, before scaling
      xOffset = 0;
      
      % how to scale raw x data, after ofsetting
      xScale = 1;
      
      % how to offset raw y data, before scaling
      yOffset = 0;
      
      % how to scale raw y data, after ofsetting
      yScale = 1;
      
      % integer identifier for x-position component
      xID = 1;
      
      % integer identifier for y-position data
      yID = 2;
      
      % integer identifier for pupil size data
      pupilID = 3;
      
      % Array of gazeWindow event structures
      gazeEvents = [];
      
      % Transforming from eye tracker space to SnowDots space:
      %   scaling
      scale=1;
      
      % Transforming from eye tracker space to SnowDots space:
      %   rotation
      rotation=1;
      
      % Transforming from eye tracker space to SnowDots space:
      %   translation
      translation=0;
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
      
      % Add gaze window as a component and associated event
      % gazeWindowName is unique string identifier
      % The remaining arguments are key/value pairs:
      %  eventName   ... Name of event used by dotsReadable.getNextEvent
      %  centerXY    ... x,y coordinates of center of gaze window
      %  channelsXY  ... Indices of data channels for x,y position
      %  windowSize  ... Diameter of circular gaze window
      %  windowDur   ... How long eye must be in window (msec) for event
      %  isInverted  ... If true, checking for *out* of window
      %  isActive    ... Flag indicating if this event is currently active
      function addGazeWindow(self, gazeWindowName, varargin)
         
         % check if it already exists
         if isempty(self.gazeEvents) || ...
               ~any(strcmp(gazeWindowName, {self.gazeEvents.gazeWindowName}))
            
            % Add window as "component"
            numComponents = numel(self.components);
            ID = numComponents + 1;
            self.components(ID).ID = ID;
            
            
            % Add the new gaze window struct to the end of the array
            index = length(self.gazeEvents) + 1;
            self.gazeEvents = cat(1, self.gazeEvents, struct( ...
               'gazeWindowName',   gazeWindowName, ...
               'ID',               ID, ...
               'eventName',        [], ...
               'channelsXY',       [self.xID self.yID], ...
               'centerXY',         [0 0], ...
               'windowSize',       3, ...
               'windowDur',        0.2, ...
               'sampleBuffer',     [], ...
               'isInverted',       false, ...
               'isActive',         false, ...
               'gazeWindowHandle', []));
         else
            
            % Use existing gaze window struct
            index = find(strcmp(gazeWindowName, {self.gazeEvents.gazeWindowName}));
         end
         
         % Parse args
         for ii=1:2:nargin-2
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
         if self.showGazeMonitor && self.gazeEvents(index).isActive
            
            % Possibly initialize the gaze monitor
            if isempty(self.gazeMonitorAxes)
               
               lims = [-self.gazeMonitorLim self.gazeMonitorLim];
               tics = -self.gazeMonitorLim:5:self.gazeMonitorLim;
               figure;
               self.gazeMonitorAxes = gca; hold on;
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
               
               % add handle to gaze data
               self.gazeMonitorDataHandle = line(0, 0, ...
                  'Color',       'r', ...
                  'Marker',      'x', ...
                  'MarkerSize',  12,  ...
                  'LineWidth',   3);
            end
            
            % Get the axes
            axes(self.gazeMonitorAxes);
            
            % Possibly make a handle to the line object that we'll use to
            % draw the gaze window circle
            if isempty(self.gazeEvents(index).gazeWindowHandle)
               self.gazeEvents(index).gazeWindowHandle = line(0,0);
            end
            
            % Update the data to draw the circle
            th = (0:pi/50:2*pi)';
            set(self.gazeEvents(index).gazeWindowHandle, ...
               'XData', ...
               self.gazeEvents(index).windowSize * cos(th) + self.gazeEvents(index).centerXY(1), ...
               'YData', ...
               self.gazeEvents(index).windowSize * sin(th) + self.gazeEvents(index).centerXY(2));
         end
      end
      
      % De-activate gaze windows
      function deactivateEvents(self)
         
         % Deactivate all of the gaze windows
         [self.gazeEvents.isActive] = deal(false);
         
         % Hide the gazeMonitor windows
         if ~isempty(self.gazeMonitorAxes)
            for ii = 1:length(self.gazeEvents)
               set(self.gazeEvents(index).gazeWindowHandle, ...
                  'XData', 0, 'YData', 0);
            end
         end
         
         % Call the readable method to deactivate all the events
         self.deactivateEvents@dotsReadable();
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
      function calibrateDevice(self)
         
         % Make a drawing ensemble for the calibration target
         calibrationEnsemble = dotsEnsembleUtilities.makeEnsemble( ...
            'calibrationEnsemble',self.ensembleRemoteInfo{:});
         
         % Generate Fixation target (cross)
         %
         % We will create a single drawable object to represent the fixation cue.
         % Then, we simply adjust the location of the cue each time we present it.
         fixationCue = dotsDrawableTargets();
         fixationCue.width  = [1 0.1] * self.calibrationFPSize;
         fixationCue.height = [0.1 1] * self.calibrationFPSize;
         calibrationEnsemble.addObject(fixationCue);
         
         % Set up matrices to present cues and collect fixation data
         FPxy = [ ...
            -self.calibrationFPX  self.calibrationFPY;
            self.calibrationFPX  self.calibrationFPY;
            self.calibrationFPX -self.calibrationFPY;
            -self.calibrationFPX -self.calibrationFPY];
         numFixations = size(FPxy, 1);
         fixationData = cell(numFixations, 1);
         
         % Loop through the fixations
         for ii = 1:numFixations
            
            % Show the fixation point
            calibrationEnsemble.setObjectProperty('xCenter', [FPxy(ii,1) FPxy(ii,1)]);
            calibrationEnsemble.setObjectProperty('yCenter', [FPxy(ii,2) FPxy(ii,2)]);
            calibrationEnsemble.callObjectMethod(@dotsDrawable.drawFrame, {}, [], true);
            
            % Wait for fixation
            pause(0.4);
            
            % flush the eye data
            self.flushData();
            
            % Collect a bunch of samples
            data = zeros(self.calibrationN, 2);
            for jj = 1:self.calibrationN
               dataMatrix = self.readRawEyeData();
               data(jj,:) = dataMatrix([self.gXID, self.gYID], 2)';
            end
            fixationData{ii} = data;
            
            % Briefly blank the screen
            calibrationEnsemble.callObjectMethod(@dotsDrawable.blankScreen, {}, [], true);
            
            % wait a moment
            pause(0.25);
         end
         
         % Clean up
         calibrationEnsemble.finish();
         
         % Find average fixation locations
         %  Try mean and median
         meanFixations = cellfun(@(X)median(X),fixationData,'UniformOutput',false);
         meanFixations = cell2mat(meanFixations);
         meanFixations = [meanFixations; meanFixations(1,:)];
         meanFixDirVectors = diff(meanFixations);
         
         cueVectors = [FPxy; FPxy(1,:)];
         cueVectors = diff(cueVectors);
         
         % Calculate scaling and rotation
         scaling = nans(size(meanFixDirVectors,1),1);
         theta   = nans(size(scaling));
         
         x = sym('x');
         for ii = 1:length(scaling)
            
            % Find average scaling
            scaling(ii) = norm(cueVectors(ii,:)) / norm(meanFixDirVectors(ii,:));
            
            % Find average rotation
            normFixDirVector = meanFixDirVectors(ii,:) / norm(meanFixDirVectors(ii,:));
            normCueVector = cueVectors(ii,:) / norm(cueVectors(ii,:));
            rot = solve(normCueVector(1) == cos(x) * normFixDirVector(1) - sin(x) * normFixDirVector(2),x);
            theta(ii) = real(double(rot(end)));
         end
         
         theta = mean(theta);
         self.scale = mean(scaling);
         self.rotation = [cos(theta) -sin(theta); sin(theta) cos(theta)];
         
         % Calculate average translation
         translations = zeros(size(scaling,1),2);
         % figure; hold on;
         % transFix = zeros(size(translations));
         for ii = 1:length(translations)
            srFixation = self.rotation * (self.scale * meanFixations(ii,:))';
            translations(ii,:) = FPxy(ii,:) - srFixation';
            % plot(srFixation(1),srFixation(2),'o');
            % transFix(ii,:) = srFixation';
         end
         self.translation = mean(translations);
         % disp('Finished snow-dots calibration');
         
         % p = transFix + repmat(self.translation,4,1);
         % plot(p(:,1),p(:,2));
         pause(0.2);
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
         
         % check whether or not we pass along all the raw data or just the
         % events
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
            
            % NOTE: FOR NOW ASSUME THAT ALL EVENTS USE THE SAME GAZE
            % CHANNELS!!! THIS CAN/SHOULD BE CHANGED IF MORE FLEXIBILITY IS
            % NEEDED, BUT FOR NOW IT SERVES TO SPEED THINGS UP
            activeIndices = find(LactiveFlags);
            
            % Get x,y samples ... these should be paired
            Lx = rawData(:,1) == self.gazeEvents(activeIndices(1)).channelsXY(1);
            Ly = rawData(:,1) == self.gazeEvents(activeIndices(1)).channelsXY(2);
            
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
            set(self.gazeMonitorDataHandle, ...
               'XData', gazeData(end,2), 'YData', gazeData(end,3));
            
            % Now loop through each active gaze event and update
            for gg = 1:length(activeIndices);
               
               ev = self.gazeEvents(activeIndices(gg));
               % disp(sprintf('checking <%s>', ev.gazeWindowName))
               
               % Calcuate number of samples to add to the buffer
               bufLen = size(ev.sampleBuffer,1);
               numSamplesToAdd = min(bufLen, numSamples);
               
               % Rotate the buffer
               ev.sampleBuffer(1:end-numSamplesToAdd,:) = ...
                  ev.sampleBuffer(1+numSamplesToAdd:end,:);
               
               % Add the new samples as a distance from center, plus the
               % timestamp. Buffer rows are [distances times]
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
                     %                                (all(Lgood(fg:end) | ~isfinite(ev.sampleBuffer(fg:end,1))))
                     
                     % Add the event to the data stream
                     newData = cat(1, newData, ...
                        [ev.ID ev.sampleBuffer(fg,[2 1])]);
                  end
               end
               
               % Save the event struct back in the object
               self.gazeEvents(activeIndices(gg))=ev;
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
         
         xSelector = newData(:,1) == self.xID;
         if any(xSelector)
            transX = self.xScale*(self.xOffset + newData(xSelector,2));
            newData(xSelector,2) = transX;
            self.x = transX(end);
         end
         
         ySelector = newData(:,1) == self.yID;
         if any(ySelector)
            transY = self.yScale*(self.yOffset + newData(ySelector,2));
            newData(ySelector,2) = transY;
            self.y = transY(end);
         end
         
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
end