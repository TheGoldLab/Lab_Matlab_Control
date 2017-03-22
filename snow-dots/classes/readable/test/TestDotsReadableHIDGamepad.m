classdef TestDotsReadableHIDGamepad < TestDotsReadableHID
    
    methods
        function self = TestDotsReadableHIDGamepad(name)
            self = self@TestDotsReadableHID(name);
        end
        
        % make a readable (test subclasses should redefine)
        function readable = newReadable(self)
            readable = dotsReadableHIDGamepad();
        end
    end
end