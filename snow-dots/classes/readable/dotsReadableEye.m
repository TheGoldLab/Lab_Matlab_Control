classdef dotsReadableEye < dotsReadable
    % @class dotsReadableEye
    % Superclass for objects that read data from an eye tracker.
    % @details
    % dotsReadableEye extends the dotsReadable superclass with support
    % for eye trackers that measuer x and y point of gaze, and pupil
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
    % rectalgles should describe the same region, such as part of a
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
    end
    
    methods (Access = protected)
        % Declare x, y, and pupil components.
        function components = openComponents(self)
            self.xID = 1;
            self.yID = 2;
            self.pupilID = 3;
            IDs = {self.xID, self.yID, self.pupilID};
            names = {'x', 'y', 'pupil'};
            components = struct('ID', IDs, 'name', names);
        end
        
        % Read and format incoming data (for subclasses).
        % @details
        % Extends the readNewData() method of dotsReadable to also
        % transform x, y, and pupil data into user-defined coordinates.
        function newData = readNewData(self)
            newData = self.transformRawData(self.readRawEyeData());
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