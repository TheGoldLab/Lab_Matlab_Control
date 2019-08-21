classdef dotsReadableDummy < dotsReadable
   % dotsReadableDummy
   %
   % A 'dummy' readable that will automatically generate inputs, usually
   % used for demo modes.
   %
   % Components are named auto_1 ... auto_n, where n is numComponents
   %
   % 9/13/18 written by jig
   
   properties
      
      % dummy components
      numComponents = 50;
      
      % values to return: 'random', 'all'
      returnValues = 'random';
      
      % pause before returning data, for pacing
      pauseBeforeReturningData = 0;      
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
            components(ii).name = sprintf('Dummy%d', ii);
         end
      end
      
      % Returns data matrix, rows are events, columns are:
      %  component ID
      %  value
      %  timestamp
      function newData = readNewData(self)
         
         % Wait
         pause(self.pauseBeforeReturningData);
         
         % Pick from active events
         activeFlags = self.getActiveFlags;
         if ~any(activeFlags)
            newData = [];
            return
         end
         
         % Return active event(s)
         switch self.returnValues
            
            case 'all'
               
               % Always return all events
               newData      = ones(sum(activeFlags, 3));               
               newData(:,1) = [self.eventDefinitions(activeFlags).ID]';
               newData(:,3) = feval(self.clockFunction);
               
            case 'random'
               
               % Return one randomly selected event
               newData = [ ...
                  self.eventDefinitions(randsample(find(activeFlags),1)).ID, ...
                  1, feval(self.clockFunction)];
         end
      end
   end
end