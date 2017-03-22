classdef dotsReadableDummy < dotsReadable
    % Testable dummy for dotsReadable superclass.  dotsReadableDummy has
    % three components which have non-sequential IDs.  Each read() call
    % increments the value of each component.
    
    properties
        % some seconds to wait between read() calls
        readDelay = 0;
    end
    
    methods
        % Constructor takes no arguments.
        function self = dotsReadableDummy()
            self = self@dotsReadable();
            self.initialize();
        end
        
        % Plot data, add a delay between read() calls.
        function plotData(self)
            self.readDelay = 0.5;
            self.plotData@dotsReadable;
            self.readDelay = 0;
        end
    end
    
    methods (Access = protected)
        % Dummy has no actual device to open or close.
        function isOpen = openDevice(self)
            isOpen = true;
        end
        
        % Dummy has no actual device to open or close.
        function closeDevice(self)
            self.isAvailable = false;
        end
        
        % Dummy has three virtual components.
        function components = openComponents(self)
            names = {'a', 'b', 'c'};
            IDs = {1, 8, 5};
            components = struct('name', names, 'ID', IDs);
        end
        
        % Dummy has no actual components to close.
        function closeComponents(self)
            self.isAvailable = false;
        end
        
        % Increment the value of each component.
        function newData = readNewData(self)
            IDs = [self.components.ID];
            newData = self.state(IDs,:);
            newData(:,2) = newData(:,2) + 1;
            newData(:,3) = newData(:,3) + 1;
            
            pause(self.readDelay);
        end
    end
    
end