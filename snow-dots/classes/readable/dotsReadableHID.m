classdef dotsReadableHID < dotsReadable
    % @class dotsReadableHID
    % Superclass for objects that read data from Human Interface Devices.
    % @details
    % dotsReadableHID extends the dotsReadable superclass with support
    % for Human Interface Devices (HID).  It uses the mexHID() mex
    % function, which is part of Snow Dots, to locate and communicate with
    % HID devices.
    % @details
    % dotsReadableHID itself is not a usable class.  It supports
    % dotsReadableHID* subclasses such as dotsReadableHIDKeyboard.
    % @details
    % mexHID() uses an internal queue to record all the value changes of
    % elements (buttons, axes, etc.) for each dotsReadableHID object.  The
    % dotsReadableHID readData() method passes any queued data into Matlab
    % via each object's appendData() method.
    properties
        % struct of info about the HID device
        deviceInfo;
        
        % struct of HID parameters for identifying suitable HID devices.
        % @details
        % Each subclass must supply parameters and values that mexHID()
        % can use to locate suitable HID devices.
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        deviceMatching;
        
        % struct of HID parameters for choosing among suitable devices.
        % @details
        % Each subclass may supply parameters and values that mexHID()
        % can use to choose among a suitable HID devices.
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        devicePreference;
        
        % size of the mexHID() internal data queue
        % @details
        % queueDepth is number of HID element value changes to keep in
        % the mexHID() internal data queue, before discarding old values.
        % This is distinct from initialEventQueueSize, which is used by all
        % dotsReadable objects.
        % @details
        % The best queueDepth depends on how fast a HID device accumulates
        % data and how often the data are read() into Matlab.
        queueDepth = 1024;
        
        % whether or not the internal data queue opened successfully
        queueIsOpen = false;
        
        % whether or not to get exclusive access to device data
        isExclusive = false;
    end
    
    properties (SetAccess = protected)
        % device identifier from mexHID('openMatchingDevice')
        % @details
        % openDevice() should fill in deviceID.
        deviceID;
        
        % Callback which mexHID() uses to pass HID data to Matlab.
        % @details
        % mexHID('check') invokes queueCallback function_handle to pass
        % formatted data into Matlab.
        % @details
        % queueCallback should be a function handle.  The corresponding
        % function must expect a dotsReadableHID object ("self") as the
        % first argument.  It must expect an nx3 matrix of component data
        % as the second argument.  It must assign new data to
        % queueCallbackData.
        queueCallback = @dotsReadableHID.mexHIDQueueCallback;
        
        % matrix of recent data passed in from mexHID()
        queueCallbackData;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsReadableHID()
            self = self@dotsReadable();
            self.clockFunction = @dotsReadableHID.currentHIDTime;
        end
        
        % Clear data from this object and the mexHID() internal queue.
        % @details
        % Extends the dotsReadable flushData() method to do also flush the
        % mexHID() internal data queue.
        function flushData(self)
            self.flushData@dotsReadable;
            if self.isAvailable
                mexHID('flushQueue', self.deviceID);
                mexHID('startQueue', self.deviceID);
            end
        end
        
        % Adjust scaling of raw values from HID components.
        % @param IDs array of component integer IDs
        % @param rawRange [min, max] raw values to work between
        % @param deadRange [min, max] raw values to treat as "middle"
        % @param calibratedRange [min, max] calibrated values to report
        % @param granularity the smallest unit of reported values
        % @details
        % setComponentCalibration() allows the raw integer values read from
        % device components to be mapped onto arbitrary,  calibrated
        % values.  Thus, components may use meaningful units.  Components
        % can also ignore unused values at the extremens of their ranges,
        % and coalesce noisy values near the middles of their ranges.
        % @details
        % @a IDs must contain one or more of the unique IDs in components.
        % Each specified component will receive the same calibration.
        % @details
        % @a rawRange specifies the range of integer values to consider
        % when reading from components.  For example, a component may have
        % a theoretical range of 0-255, @a rawRange might specify a
        % smaller acheivable range, perhaps 10-245.  Values outside of @a
        % rawRange are clipped.
        % @details
        % @a deadRange specifies a range of values near the "middle" of
        % @a rawRange.  All values within @a deadRange are coalesced and
        % reported as the "middle" value.  For example, a joystick might
        % need to treat several appriximately centered values as properly
        % centered.
        % @details
        % @a calibratedRange specifies the range of values to be reported.
        % The min and max of @a rawRange are mapped to the min and max of
        % @a calibratedRange, respectively.  Intermediate raw values are
        % mapped to intermediate calibrated values linearly.
        % @details
        % @a granularity specifies the smallest step between calibrated
        % values.  Reported values will be integer multiples of @a
        % granularity.
        % @details
        % If any of @a rawRange, @a deadRange, @a calibratedRange, or @a
        % granularity is empty or omitted, the present value is used.
        function components = setComponentCalibration(self, IDs, ...
                rawRange, deadRange, calibratedRange, granularity)
            
            % find components indexes for each ID
            allIDs = [self.components.ID];
            nCalib = numel(IDs);
            compIndexes = zeros(1, nCalib);
            for ii = 1:nCalib
                compIndexes(ii) = find(allIDs == IDs(ii), 1, 'first');
            end
            
            % get the HID cookie for each ID
            calibCookies = [self.components(compIndexes).ElementCookie];
            
            % get struct array with the current calibration values
            calibNames = { ...
                'CalibrationSaturationMin', 'CalibrationSaturationMax', ...
                'CalibrationDeadZoneMin', 'CalibrationDeadZoneMax', ...
                'CalibrationMin', 'CalibrationMax', ...
                'CalibrationGranularity'};
            calibVals = mexHID('getElementProperties', ...
                self.deviceID, calibCookies, calibNames);
            
            % replace current values with supplied values
            if nargin >= 3 && ~isempty(rawRange)
                [calibVals.CalibrationSaturationMin] = deal(rawRange(1));
                [calibVals.CalibrationSaturationMax] = deal(rawRange(2));
            end
            
            if nargin >= 4 && ~isempty(deadRange)
                [calibVals.CalibrationDeadZoneMin] = deal(deadRange(1));
                [calibVals.CalibrationDeadZoneMax] = deal(deadRange(2));
            end
            
            if nargin >= 5 && ~isempty(calibratedRange)
                [calibVals.CalibrationMin] = deal(calibratedRange(1));
                [calibVals.CalibrationMax] = deal(calibratedRange(2));
            end
            
            if nargin >= 6 && ~isempty(granularity)
                [calibVals.CalibrationGranularity] = deal(granularity);
            end
            
            % set updated values to components
            mexHID('setElementProperties', ...
                self.deviceID, calibCookies, calibVals);
            
            % re-get element properties following the update
            calibVals = mexHID('getElementProperties', ...
                self.deviceID, calibCookies, calibNames);
            
            % replace elements of components with updated values
            for ii = 1:numel(calibNames)
                name = calibNames{ii};
                [self.components(compIndexes).(name)] = ...
                    deal(calibVals.(name));
            end
            
            % return info about each calibrated component
            components = self.components(compIndexes);
        end
    end
    
    methods (Access = protected)
        % Find the best available HID device with mexHID().
        function isOpen = openDevice(self)
            isOpen = false;
            if exist('mexHID', 'file')
                
                if ~mexHID('isInitialized')
                    mexHID('initialize');
                end
                
                self.closeDevice();
                self.deviceID = -1;
                
                % Try to open the preferred device
                if isstruct(self.devicePreference)
                    deviceMerged = self.deviceMatching;
                    prefFields = fieldnames(self.devicePreference);
                    for ii = 1:numel(prefFields)
                        field = prefFields{ii};
                        deviceMerged.(field) = ...
                            self.devicePreference.(field);
                    end
                    self.deviceID = mexHID('openMatchingDevice', ...
                        deviceMerged, double(self.isExclusive));
                end
                
                % Fall back on any matching device
                if self.deviceID <= 0;
                    self.deviceID = mexHID('openMatchingDevice', ...
                        self.deviceMatching, double(self.isExclusive));
                end
                
                isOpen = self.deviceID > 0;
            end
            
            if isOpen
                self.deviceInfo = ...
                    mexHID('getDeviceProperties', self.deviceID);
            end
        end
        
        % Release mexHID() resources for this device.
        function closeDevice(self)
            mexHID('closeDevice', self.deviceID);
            self.deviceID = -1;
            self.queueIsOpen = false;
        end
        
        % Open a queue to record value changes for device elements.
        % @details
        % Adds the device elements identified by queueCookies to a queue to
        % have their value changes recorded.  Other device elements will be
        % left out of the queue, so their values will be ignored.
        % @details
        % Returns true if mexHID successfully created the queue and added
        % queueCookies elements were added to it.  The queue will start
        % recording value changes immediately.
        function isOpen = openHIDQueue(self, cookies)
            isOpen = false;
            if ~isempty(cookies) && all(cookies > 0)
                
                qcb = {self.queueCallback, self};
                queueStatus = mexHID('openQueue', ...
                    self.deviceID, cookies, qcb, self.queueDepth);
                
                if queueStatus >= 0
                    queueStatus = mexHID('startQueue', self.deviceID);
                end
                
                isOpen = queueStatus >= 0;
                self.queueIsOpen = isOpen;
            end
        end
        
        % Pass any data from the mexHID() internal queue to this object().
        % @details
        % Moves data from the mexHID() internal queue into Matlab via the
        % queueCallback function and queueCallbackData property.
        function newData = readNewData(self)
            % read down the mexHID internal queue of element value changes
            % 	new data are assigned to queueCallbackData
            %   by mexHID('check'), via the queueCallback function
            mexHID('check');
            newData = self.queueCallbackData;
            
            % only process new data once
            self.queueCallbackData = [];
        end
    end
    
    methods (Static)
        % Pass data from the mexHID() internal queue to Matlab.
        function mexHIDQueueCallback(self, newData)
            self.queueCallbackData = newData;
        end
        
        % Get the current time from the system USB/HID implementation.
        function time = currentHIDTime()
            time = mexHID('check');
        end
    end
end