classdef dotsReadableHIDKeyboard < dotsReadableHID
   % @class dotsReadableHIDKeyboard
   % Reads data from a HID keyboard device.
   % @details
   % dotsReadableHIDKeyboard extends the dotsReadableHID superclass to
   % manage HID keyboard devices.  Many integrated and USB keybords are
   % HID keyboards.
   % @details
   % By default, dotsReadableHIDKeyboard defines "pressed" events for
   % each keyboard key.  Use getNextEvent() to make sure that no key
   % presses are missed, and that each press is observed only once.
   %
   % Example usage:
   %  kb = dotsReadableHIDKeyboard();
   %  [isPressed, waitTime, data, kbout] = dotsReadableHIDKeyboard.waitForKeyPress(kb, 'KeyboardF', 5, true)
   
   properties
      % struct of HID parameters to identify the key elements of the
      % keyboard.
      % @details
      % See mexHIDUsage() or mexHIDUsage.gui() for lists of valid HID
      % parameters.
      keyMatching;
      
      % matching preferences read from machine defaults
      VendorID;
      ProductID;
      PrimaryUsage;

      % Get rid of annoying rollover event     
   end
   
   methods
      % Constructor may take device matching preferences.
      % @param devicePreference struct of HID matching parameters
      % @details
      % @a devicePreference is an optional struct of HID parameters for
      % choosing among suitable devices, assigned to the
      % devicePreference property.
      function self = dotsReadableHIDKeyboard(devicePreference)
         self = self@dotsReadableHID();
         
         % Read args
         if nargin > 0
            
            % Preferences given
            self.devicePreference = devicePreference;
         else
            
            % Read machine defaults
            mc = dotsTheMachineConfiguration.theObject();
            mc.applyClassDefaults(self);
            
            % Put preferences into the struct
            self.devicePreference.VendorID = self.VendorID;
            self.devicePreference.ProductID = self.ProductID;
            self.devicePreference.PrimaryUsage = self.PrimaryUsage;
            
            % special case for jig computer without external keyboard
            if strcmp(getMachineName(), 'GoldLaptop')
               mexHID('initialize');
               infoStruct = mexHID('summarizeDevices');
               if ~any([infoStruct.VendorID] == self.VendorID)
                  self.devicePreference.VendorID = 1452;
                  self.devicePreference.ProductID = 632;
               end
            end
         end
         
         % choose basic device identification criteria
         usagePage = mexHIDUsage.numberForPageName('GenericDesktop');
         usage = mexHIDUsage.numberForUsageNameOnPage( ...
            'Keyboard', usagePage);
         self.deviceMatching.PrimaryUsagePage = usagePage;
         self.deviceMatching.PrimaryUsage = usage;
         
         % choose basic key selection criteria
         usagePage = mexHIDUsage.numberForPageName('KeyboardOrKeypad');
         self.keyMatching.UsagePage = usagePage;
         
         % open device and elements
         self.initialize();
         
         % define the "pressed" event for each key
         self.defineEventsFromComponents();
   
         % flush
         self.flushData();
      end
   end
   
   methods (Access = protected)
      
      % Locate and enqueue all the keys of the keyboard.
      function components = openComponents(self)
         
         % find all keyboard keys
         keyCookies = mexHID('findMatchingElements', ...
            self.deviceID, self.keyMatching);
         
         keyInfo = mexHID('summarizeElements', ...
            self.deviceID, keyCookies);
         
         nKeys = numel(keyCookies);
         keyNames = cell(1, nKeys);
         keyIDs = cell(1, nKeys);
         isNamed = false(1, nKeys);
         for ii = 1:nKeys
            keyNames{ii} = mexHIDUsage.nameForUsageNumberOnPage( ...
               keyInfo(ii).Usage, keyInfo(ii).UsagePage);
            isNamed(ii) = ~isempty(keyNames{ii});
            keyIDs{ii} = keyInfo(ii).ElementCookie;
         end
         
         % filter out the unnamed "keys"
         components = keyInfo(isNamed);
         [components.name] = deal(keyNames{isNamed});
         [components.ID] = deal(keyIDs{isNamed});
         
         % queue value changes for named keys
         self.openHIDQueue([components.ElementCookie]);
      end
      
      % Unenqueue all the keys of the keyboard.
      function closeComponents(self)
         mexHID('stopQueue', self.deviceID);
      end
   end
   
   methods (Static)
      
      % Open all of the available HID keyboards.
      % @details
      % Scans for connected HID keyboards and constructs a
      % dotsReadableHIDKeyboard object for each.  Returns the objectss
      % as an array of dotsReadableHIDKeyboard.
      function kbs = openManyKeyboards()
         
         % cast a broad net for keyboards
         usagePage = mexHIDUsage.numberForPageName('GenericDesktop');
         usage = mexHIDUsage.numberForUsageNameOnPage( ...
            'Keyboard', usagePage);
         
         % scan for all HID devices
         if ~mexHID('isInitialized')
            mexHID('initialize');
         end
         deviceInfo = mexHID('summarizeDevices');
         
         % pick out keyboard devices
         isKb = [deviceInfo.PrimaryUsagePage] == usagePage ...
            & [deviceInfo.PrimaryUsage] == usage;
         
         % construct an instance for each keyboard
         kbIndices = find(isKb);
         nKeyboards = numel(kbIndices);
         kbCell = cell(1, nKeyboards);
         for ii = 1:nKeyboards
            preference = deviceInfo(kbIndices(ii));
            kbCell{ii} = dotsReadableHIDKeyboard(preference);
         end
         kbs = [kbCell{:}];
      end
      
      % Close several HID keyboards.
      % @param kbs array of dotsReadableHIDKeyboard objects
      % @details
      % Invokes close() on each of the given dotsReadableHIDKeyboard
      % objects.  Objects should be re-initialized or discarded.
      function closeManyKeyboards(kbs)
         nKeyboards = numel(kbs);
         for ii = 1:nKeyboards
            kbs(ii).close();
         end
      end
      
      % Is the given key pressed, on one or many keyboards?
      % @param kbs array of dotsReadableHIDKeyboard objects
      % @param keyName the HID usage name of a keyboard key
      % @details
      % Creates a "pressed" event for the given @a keyName, on each of
      % the given @a kbs.  Checks whether the pressed event is happening
      % on any of the given @a kbs.
      % @details
      % Returns true if any of given @a kbs has @a keyName currently
      % pressed.  Returns as a second output the data associated with
      % the key press.  The data has the form [ID, value, time].  Returns
      % as a third output the keyboard object on which the key is
      % pressed.  If keyboard has the key pressed, returns only the first
      % one.
      function [isPressed, data, kb] = isKeyPressed(kbs, keyName)
         
         nKeyboards = numel(kbs);
         for ii = 1:nKeyboards
            event = kbs(ii).defineEvent(keyName, 'isActive', true);
         end
         
         [isPressed, data, kb] = ...
            dotsReadable.isEventHappening(kbs, event.name);
      end
      
      % Wait for given key to be pressed, on one or many keyboards.
      % @param kbs array of dotsReadableHIDKeyboard objects
      % @param keyName the HID usage name of a keyboard key
      % @param maxWait maximum time to wait for key press
      % @details
      % Creates a "pressed" event for the given @a keyName, on each of
      % the given @a kbs.  Waits for one of of the given @a kbs to report
      % that the given @a keyName was pressed.  @a maxWait specifies how
      % long to wait before giving up.  Uses currentTime() of the first
      % object to keep track of time.  Invokes read() and checks each
      % object for events at least once, even if @a maxWait is zero or
      % negative.
      % @details
      % Returns true if any of given @a kbs reports that @a
      % keyName was pressed, before @a maxWait.  Returns as a second
      % output the amout of time waited.  Returns as a third output the
      % data associated with the key press.  The data has the form [ID,
      % value, time].  Returns as a fourth output the object which
      % reported the key press.  If more than one keyboard can report
      % that the key was pressed, only the first one is returned.
      function [isPressed, waitTime, data, kb] = ...
            waitForKeyPress(kbs, keyName, maxWait, flush)
         
         % flush event queue
         if nargin >= 4 && flush
            kbs.flushData();
         end
         
         % get event name
         nKeyboards = numel(kbs);
         for ii = 1:nKeyboards
            event = kbs(ii).defineEvent(keyName, 'isActive', true);
         end
                  
         [isPressed, waitTime, data, kb] = ...
            dotsReadable.waitForEvent(kbs, event.name, maxWait);
      end
   end
end