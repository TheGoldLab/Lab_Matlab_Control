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
        
        % Flag determining whether only to read event data
        %  see readNewData for details. This defaults to 'true' because
        %  typically we assume that eye tracking data will be stored
        %  separately.
        readEventsOnly = true;
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
                    'gazeWindowName', gazeWindowName, ...
                    'ID',             ID, ...
                    'eventName',      [], ...
                    'channelsXY',     [self.xID self.yID], ...
                    'centerXY',       [0 0], ...
                    'windowSize',     1, ...
                    'windowDur',      0.2, ...
                    'eventQueue',     [], ...
                    'isInverted',     false, ...
                    'isActive',       false));
                
                % Be nice and keep track of when we need to call
                % dotsReadable.defineEvent
                updateEvent = true;
            else
                
                % Use existing gaze window struct
                index = find(strcmp(gazeWindowName, {self.gazeEvents.gazeWindowName}));
                
                % Only if eventName is given
                updateEvent = any(strcmp('eventName', varargin));
            end
            
            % Parse args
            for ii=1:2:nargin-2
                self.gazeEvents(index).(varargin{ii}) = varargin{ii+1};
            end
            
            % Check/clear event queue
            len = self.gazeEvents(index).windowDur*self.sampleFrequency+2;
            if length(self.gazeEvents(index).eventQueue) ~= len
                self.gazeEvents(index).eventQueue = nans(len,2);
            else
                self.gazeEvents(index).eventQueue(:) = nan;
            end
            
            % Now add it to the dotsReadable event queue. We do all the heavy
            % lifting here, in getNewData, to determine if an event actually
            % happened. As a consequence, we only send real events and don't
            % require dotsReadable.detectEvent to make any real comparisons,
            % which is why we set the min/max values to -/+inf.
            if updateEvent
                eventName = self.gazeEvents(index).eventName;
                self.components(ID).name = eventName;
                self.defineEvent(ID, eventName, -inf, inf, false);
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
                
                % Now loop through each active gaze event and update
                for gg = 1:length(activeIndices);
                    
                    ev = self.gazeEvents(gg);
                    
                    % Calcuate number of samples to add to the buffer
                    bufLen = size(ev.gazeEventsQueue,1);
                    numSamplesToAdd  = min(bufLen, numSamples);
                    
                    % Rotate the buffer
                    ev.gazeEventsQueue(1:end-numSamplesToAdd,:) = ...
                        ev.gazeEventsQueue(1+numSamplesToAdd:end,:);
                    
                    % Add the new samples as a distance from center, plus the
                    % timestamp. Buffer rows are [times, distances]
                    inds = (bufLen-numSamplesToAdd+1):bufLen;
                    ev.gazeEventsQueue(end-numSamplesToAdd+1:end,:) = [
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
                    Lgood = ev.gazeEventsQueue(:,2) <= ev.windowSize;
                    if ev.isInverted
                        Lgood = ~Lgood;
                    end
                    if Lgood(end) && any(Lgood(1:end-1))
                        fg = find(Lgood,1);
                        if (ev.gazeEventsQueue(fg,1) <= ...
                                (ev.gazeEventsQueue(end,1) - ev.windowDur)) && ...
                                (all(Lgood(fg:end) | ~isfinite(ev.gazeEventsQueue(fg:end,1))))
                            
                            % Add the event to the data stream
                            newData = cat(1, newData, ...
                                [ev.ID ev.gazeEventsQueue(fg,:)]);
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
    end
end