classdef dotsReadableHIDGamepad < dotsReadableHID
    % @class dotsReadableHIDGamepad
    % Reads data from a HID gamepad device.
    % @details
    % dotsReadableHIDGamepad extends the dotsReadableHID superclass to
    % manage HID Gamepad devices.  Many USB gamepads and joysticks are
    % considered HID gamepads.
    % @details
    % By default, dotsReadableHIDGamepad defines "pressed" events for
    % each gamepad button.  Use getNextEvent() to make sure that no
    % presses are missed, and that each press is observed only once.
    properties
        % HID usage names that are consistent with "gamepad"
        gamepadUsages = {'GamePad', 'Joystick', 'MultiAxisController'};
        
        % struct of HID parameters to identify gamepad button elements
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        buttonMatching;
        
        % struct of HID parameters to identify the gamepad x-axis element
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        xMatching;
        
        % struct of HID parameters to identify the gamepad y-axis element
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        yMatching;
        
        % struct of HID parameters to identify the gamepad z-axis element
        % @details
        % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
        % parameters.
        zMatching;
    end
    
    properties (SetAccess = protected)
        % ID of the x-axis component
        xID;
        
        % ID of the y-axis component
        yID;
        
        % ID of the z-axis component (if any)
        zID;
        
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
        function self = dotsReadableHIDGamepad(devicePreference)
            self = self@dotsReadableHID();
            
            if nargin > 0
                self.devicePreference = devicePreference;
            end
            
            % choose button selection criteria
            usagePage = mexHIDUsage.numberForPageName('Button');
            self.buttonMatching.UsagePage = usagePage;
            
            % choose x y and z axis selection criteria
            usagePage = mexHIDUsage.numberForPageName('GenericDesktop');
            usage = mexHIDUsage.numberForUsageNameOnPage('X', usagePage);
            self.xMatching.UsagePage = usagePage;
            self.xMatching.Usage = usage;
            usage = mexHIDUsage.numberForUsageNameOnPage('Y', usagePage);
            self.yMatching.UsagePage = usagePage;
            self.yMatching.Usage = usage;
            usage = mexHIDUsage.numberForUsageNameOnPage('Z', usagePage);
            self.zMatching.UsagePage = usagePage;
            self.zMatching.Usage = usage;
            
            % choose basic device identification criteria
            %   try a few usages which are consistent with "gamepad"
            usagePage = mexHIDUsage.numberForPageName('GenericDesktop');
            self.deviceMatching.PrimaryUsagePage = usagePage;
            for ii = 1:numel(self.gamepadUsages)
                % get the number for a gamepad-like usage name
                usage = mexHIDUsage.numberForUsageNameOnPage( ...
                    self.gamepadUsages{ii}, usagePage);
                self.deviceMatching.PrimaryUsage = usage;
                
                % try for a gamepad-like device
                self.initialize();
                if self.isAvailable
                    break;
                end
            end
            
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
    end
    
    methods (Access = protected)
        % Locate and enqueue buttons and axes of the gamepad
        function components = openComponents(self)
            % find all gamepad buttons
            buttonCookies = mexHID('findMatchingElements', ...
                self.deviceID, self.buttonMatching);
            
            buttonInfo = mexHID('summarizeElements', ...
                self.deviceID, buttonCookies);
            
            nButtons = numel(buttonCookies);
            names = cell(1, nButtons);
            IDs = cell(1, nButtons);
            for ii = 1:nButtons
                names{ii} = mexHIDUsage.nameForUsageNumberOnPage( ...
                    buttonInfo(ii).Usage, buttonInfo(ii).UsagePage);
                IDs{ii} = buttonInfo(ii).ElementCookie;
            end
            
            buttons = buttonInfo;
            [buttons.name] = deal(names{:});
            [buttons.ID] = deal(IDs{:});
            self.buttonIDs = [buttons.ID];
            
            % find x and y axes
            xCookie = mexHID('findMatchingElements', ...
                self.deviceID, self.xMatching);
            if xCookie > 0
                xInfo = mexHID('summarizeElements', ...
                    self.deviceID, xCookie);
                xInfo.name = 'x';
                xInfo.ID = xInfo.ElementCookie;
                self.xID = xInfo.ElementCookie;
            else
                xInfo = [];
            end
            
            yCookie = mexHID('findMatchingElements', ...
                self.deviceID, self.yMatching);
            if yCookie > 0
                yInfo = mexHID('summarizeElements', ...
                    self.deviceID, yCookie);
                yInfo.name = 'y';
                yInfo.ID = yInfo.ElementCookie;
                self.yID = yInfo.ElementCookie;
            else
                yInfo = [];
            end
            
            zCookie = mexHID('findMatchingElements', ...
                self.deviceID, self.zMatching);
            if zCookie > 0
                zInfo = mexHID('summarizeElements', ...
                    self.deviceID, zCookie);
                zInfo.name = 'z';
                zInfo.ID = zInfo.ElementCookie;
                self.zID = zInfo.ElementCookie;
            else
                zInfo = [];
            end
            
            % queue value changes for buttons and axes
            components = cat(1, xInfo, yInfo, zInfo, buttons(:));
            self.openHIDQueue([components.ElementCookie]);
        end
        
        % Unenqueue all the buttons of the Gamepad.
        function closeComponents(self)
            mexHID('stopQueue', self.deviceID);
        end
    end
end