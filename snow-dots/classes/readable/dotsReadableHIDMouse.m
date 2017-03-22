classdef dotsReadableHIDMouse < dotsReadableHID
    % @class dotsReadableHIDMouse
    % Reads data from a HID mouse device.
    % @details
    % dotsReadableHIDMouse extends the dotsReadableHID superclass to
    % manage HID mouse devices.  Many integrated and USB pointing devices
    % can be considered HID mouses.
    % @details
    % By default, dotsReadableHIDMouse defines "pressed" events for
    % each mouse button.  Use getNextEvent() to make sure that no clicks
    % are missed, and that each click is observed only once.
    % @details
    % Note that HID mouses report x and y data as position changes, rather
    % than absolute positions.  Usually the operating system integrates the
    % changes with some scaling and nonlinearity.  dotsReadableHIDMouse
    % automatically sums x and y component values as they arrive, without
    % any scaling or nonlinearity.  The latest sums are available in the x
    % and y properties.
    properties
        % struct of HID parameters to identify mouse button elements
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        buttonMatching;
        
        % struct of HID parameters to identify mouse x-axis element
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        xMatching;
        
        % struct of HID parameters to identify mouse y-axis element
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        yMatching;
        
        % the latest x-position of the mouse
        x;
        
        % the latest y-position of the mouse
        y;
    end
    
    properties (SetAccess = protected)
        % ID of the x-axis component
        xID;
        
        % ID of the y-axis component
        yID;
        
        % ID of button components
        buttonIDs;
    end

    methods
        % Constructor may take device matching preferences.
        % @param devicePreference struct of HID matching parameters
        % @details
        % @a devicePreference is an optional struct of HID parameters for
        % choosing among suitable devices, assigned to the
        % devicePreference property.
        function self = dotsReadableHIDMouse(devicePreference)
            self = self@dotsReadableHID();
            
            if nargin > 0
                self.devicePreference = devicePreference;
            end
            
            % choose basic device identification criteria
            usagePage = mexHIDUsage.numberForPageName('GenericDesktop');
            usage = mexHIDUsage.numberForUsageNameOnPage( ...
                'Mouse', usagePage);
            self.deviceMatching.PrimaryUsagePage = usagePage;
            self.deviceMatching.PrimaryUsage = usage;
            
            % choose button selection criteria
            usagePage = mexHIDUsage.numberForPageName('Button');
            self.buttonMatching.UsagePage = usagePage;
            
            % choose x anx y axis selection criteria
            usagePage = mexHIDUsage.numberForPageName('GenericDesktop');
            usage = mexHIDUsage.numberForUsageNameOnPage('X', usagePage);
            self.xMatching.UsagePage = usagePage;
            self.xMatching.Usage = usage;
            usage = mexHIDUsage.numberForUsageNameOnPage('Y', usagePage);
            self.yMatching.UsagePage = usagePage;
            self.yMatching.Usage = usage;
            
            % use a special callback which sums x and y change data
            self.queueCallback = ...
                @dotsReadableHIDMouse.mexHIDMouseQueueCallback;
            
            % open device and elements
            self.initialize();
            
            % define the "pressed" event for each button
            IDs = [self.components.ID];
            nButtons = numel(self.buttonIDs);
            for ii = 1:nButtons
                isThisButton = IDs == self.buttonIDs(ii);
                comp = self.components(isThisButton);
                eventName = ['pressed ' comp.name];
                highValue = comp.CalibrationMax;
                self.defineEvent(comp.ID, eventName, highValue, highValue);
            end
        end
        
        % Flush data and reset the x and y position running sums.
        function flushData(self)
            self.flushData@dotsReadableHID();
            self.x = 0;
            self.y = 0;
        end
    end
    
    methods (Access = protected)
        % Locate and enqueue all the buttons and axes of the mouse.
        function components = openComponents(self)
            % find mouse buttons
            buttonCookies = mexHID('findMatchingElements', ...
                self.deviceID, self.buttonMatching);
            
            buttonInfo = mexHID('summarizeElements', ...
                self.deviceID, buttonCookies);
            
            nButtons = numel(buttonCookies);
            names = cell(1, nButtons);
            IDs = cell(1, nButtons);
            isNamed = false(1, nButtons);
            for ii = 1:nButtons
                names{ii} = mexHIDUsage.nameForUsageNumberOnPage( ...
                    buttonInfo(ii).Usage, buttonInfo(ii).UsagePage);
                isNamed(ii) = ~isempty(names{ii});
                IDs{ii} = buttonInfo(ii).ElementCookie;
            end
            
            % filter out the unnamed "buttons"
            buttons = buttonInfo(isNamed);
            [buttons.name] = deal(names{isNamed});
            [buttons.ID] = deal(IDs{isNamed});
            self.buttonIDs = [buttons.ID];
            
            % find x and y axes
            xCookie = mexHID('findMatchingElements', ...
                self.deviceID, self.xMatching);
            xInfo = mexHID('summarizeElements', ...
                self.deviceID, xCookie);
            xInfo.name = 'x';
            xInfo.ID = xInfo.ElementCookie;
            self.xID = xInfo.ElementCookie;
            
            yCookie = mexHID('findMatchingElements', ...
                self.deviceID, self.yMatching);
            yInfo = mexHID('summarizeElements', ...
                self.deviceID, yCookie);
            yInfo.name = 'y';
            yInfo.ID = yInfo.ElementCookie;
            self.yID = yInfo.ElementCookie;
            
            % queue value changes for buttons and axes
            components = cat(1, xInfo, yInfo, buttons(:));
            self.openHIDQueue([components.ElementCookie]);
        end
        
        % Unenqueue all the buttons and elements of the mouse.
        function closeComponents(self)
            mexHID('stopQueue', self.deviceID);
        end
    end
    
    methods (Static)
        % Pass data from the mexHID() internal queue to Matlab.
        % @details
        % Keep running sums of x and y data.
        function mexHIDMouseQueueCallback(self, newData)
            isX = newData(:,1) == self.xID;
            if any(isX)
                newData(isX,2) = self.x + cumsum(newData(isX,2));
                lastX = find(isX, 1, 'last');
                self.x = newData(lastX,2);
            end
            
            isY = newData(:,1) == self.yID;
            if any(isY)
                newData(isY,2) = self.y + cumsum(newData(isY,2));
                lastY = find(isY, 1, 'last');
                self.y = newData(lastY,2);
            end
            
            self.queueCallbackData = newData;
        end
    end
end