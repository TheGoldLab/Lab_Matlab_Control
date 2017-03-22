classdef TestDotsReadableHIDKeyboard < TestDotsReadableHID
    
    methods
        function self = TestDotsReadableHIDKeyboard(name)
            self = self@TestDotsReadableHID(name);
        end
        
        % make a readable (test subclasses should redefine)
        function readable = newReadable(self)
            readable = dotsReadableHIDKeyboard();
        end
        
        function testOpenMany(self)
            % open many keyboards, and no other devices
            mexHID('terminate');
            kbs = dotsReadableHIDKeyboard.openManyKeyboards();
            
            % make sure keyboards agree with opened devices
            openDevices = mexHID('getOpenedDevices');
            assertEqual(sort(openDevices), sort([kbs.deviceID]), ...
                'opened keyboards do not match opened devices');
            
            % close all the keyboards
            dotsReadableHIDKeyboard.closeManyKeyboards(kbs);
            
            % make sure no more devices are open
            openDevices = mexHID('getOpenedDevices');
            assertTrue(isempty(openDevices), ...
                'not all keyboards were closed');
        end
    end
end