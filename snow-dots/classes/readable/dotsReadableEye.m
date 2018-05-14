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
      
      % minimum duration of a 
   end
   
   properties (SetAccess = protected)
      % how to offset raw x data, before scaling
      xOffset;
      
      % how to scale raw x data, after ofsetting
      xScale;
      
      % how to offset raw y data, before scaling
      yOffset;
      
      % how to scale raw y data, after ofsetting
      yScale;
      
      % integer identifier for x-position component
      xID = 1;
      
      % integer identifier for y-position data
      yID = 2;
      
      % integer identifier for pupil size data
      pupilID = 3;
      
      % Array of gazeWindow event structures
      gazeEvents = [];
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
      % gazeWindowName is used as the event name
      function addGazeEvent(self, gazeWindowName, eventName, centerXY, ...
            windowSize, isInverted, historyLength, isActive)
         
         % check arg
         if nargin < 4 || isempty(centerXY)
            centerXY = [0 0];
         end
         if nargin < 5 || isempty(windowSize)
            windowSize = 1;
         end
         
         % Add window as "component"
         ID = size(self.components,2) + 1;
         self.components(numComponents).ID = numComponents;
         self.components(numComponents).name = eventName;
         
         % Make gaze event to store locally, to be able to activate/
         % deactivate it at will)
         gazeEventIndex = length(self.gazeEvents) + 1;
         self.gazeEvents(gazeEventIndex).gazeWindowName = gazeWindowName;
         self.gazeEvents(gazeEventIndex).eventName = eventName;
         self.gazeEvents(gazeEventIndex).ID = ID;
         self.gazeEvents(gazeEventIndex).center = center;
         self.gazeEvents(gazeEventIndex).diameter = diameter;
         self.gazeEvents(gazeEventIndex).isInverted = isInverted;
         self.gazeEvents(gazeEventIndex).isActive = isActive;
         
         % Now add it to the dotsReadable event queue
         defineEvent(self, ID, eventName, 0, diameter, isInverted);         
      end
      
      % activate
      function activateGazeWindow(self, gazeWindowName, eventName)
         
         % Get event index
         gazeEventIndex = find(strcmp(gazeWindowName, {self.gazeEvents.name}));
         
         % Check if already active
         if self.gazeEvents(gazeEventIndex).isActive
            return
         end
         
         % check argument
         if nargin > 2 || ~isempty(eventName)
            self.gazeEvents(gazeEventIndex).eventName = eventName;
         end
         
         % Set active flag
         self.gazeEvents(gazeEventIndex).isActive = true;

         % Re-set dotsReadable event
         ID = getComponentIDbyName(self, gazeWindowName);
         self.eventDefinitions(ID).name = self.gazeEvents(gazeEventIndex).eventName;
         self.eventDefinitions(ID).lowValue = 0;
         self.eventDefinitions(ID).highValue = self.gazeEvents(gazeEventIndex).diameter;
         self.eventDefinitions(ID).isInverted = self.gazeEvents(gazeEventIndex).isInverted;
      end
      
      % De-activate
      function deactivateGazeWindow(self, gazeWindowName)

         % Get event index
         gazeEventIndex = find(strcmp(gazeWindowName, {self.gazeEvents.name}));
         
         % Check if already inactive
         if ~self.gazeEvents(gazeEventIndex).isActive
            return
         end

         % Unset active flag
         self.gazeEvents(gazeEventIndex).isActive = false;

         % Undefine dotsReadable event
         undefineEvent(self, self.gazeEvents(gazeEventIndex).ID)
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
         newData = self.transformRawData(self.readRawEyeData());
         
         % update gaze window data by computing distance of gaze
         %  to center of each window
         if ~isempty(self.gazeEvents)
            
            newEvents = [];
            
            % For each active gaze event, update gaze distance queue
            for gg = find([self.gazeEvents.isActive])
               
               ev = self.gazeEvents(gg);
               
               % Rotate the buffer
               ev.gazeEventsQueue(1:end-1,:) = ...
                  ev.gazeEventsQueue(2:end,:);
               
               % Add the new sample as a distance from center
               ev.gazeEventsQueue(end,:) = [ ...
                  sqrt( ...
                  (newData(ev.xChannel,2)-ev.centerXY(1)).^2 + ...
                  (newData(ev.yChannel,2)-ev.centerXY(2)).^2), ...
                  newData(ev.xChannel,3)];
               
               % Check for event:
               %  1. current sample is in acceptance window
               %  2. at least one other sample is in acceptance window
               %  3. earlist sample in acceptance window was at least
               %     historyLength in the past
               %  4. no intervening samples were outside window
               Lgood = ev.gazeEventsQueue(:,1) <= ev.windowSize;
               if ev.isInverted
                  Lgood = ~Lgood;
               end
               if Lgood(end) && any(Lgood(1:end-1))
                  fg = find(Lgood,1);
                  if (ev.gazeEventsQueue(fg,2) <= ...
                     (ev.gazeEventsQueue(end,2) - ev.historyLength)) && ...
                     (all(Lgood(fg:end) | isfinite(ev.gazeEventsQueue(fg:end,1))))
                     
                     % Add the event to the data stream
                     newData = cat(1, newData, ...
                        [ev.ID ev.gazeEventsQueue(end,:)]);
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

      % Overloaded method for detecting events
      function isEvent = detectEvents(self, data)
     
   end
end