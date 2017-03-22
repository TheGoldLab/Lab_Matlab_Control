classdef TestDotsReadableHIDMouse < TestDotsReadableHID
    
    methods
        function self = TestDotsReadableHIDMouse(name)
            self = self@TestDotsReadableHID(name);
        end
        
        % make a readable (test subclasses should redefine)
        function readable = newReadable(self)
            readable = dotsReadableHIDMouse();
        end
    end
end