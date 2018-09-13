classdef dotsReadableDummy < dotsReadable
   % dotsReadableDummy
   %
   % To run in demo mode
   %
   % 9/13/18 written by jig
   
   properties
      
      % dummy components
      numComponents = 10;
      
      % pause before returning data, for pacing
      pauseBeforeReturningData = 0.6;
      
   end
   
   properties (SetAccess = private)
      
   end
   
   %% Public method
   methods
      
      % Constructor method
      function self = dotsReadableDummy()
         self = self@dotsReadable();
         
         % Initialize the object
         self.initialize();
      end
   end
   
   %% Protected methods
   methods (Access = protected)
      
      % openDevice
      %
      function isOpen = openDevice(self)
         isOpen = true;
      end
      
      % Just one component
      function components = openComponents(self)
         
         % Make the components
         components = struct('ID', num2cell(1:self.numComponents), 'name', []);         
         for ii = 1:self.numComponents
            components(ii).name = sprintf('auto_%d', ii);
         end
      end
      
      function newData = readNewData(self)
         
         pause(self.pauseBeforeReturningData);
         
         % always return auto events
         newData = ones(self.numComponents, 3);
         newData(:,1) = 1:self.numComponents;
         newData(:,3) = feval(self.clockFunction);
      end
   end
end