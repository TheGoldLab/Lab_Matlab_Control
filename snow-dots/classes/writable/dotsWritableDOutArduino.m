
classdef dotsWritableDOutArduino < dotsWritableDOut
   % @class dotsWritableDOutArduino
   %
   % Implement digital outputs using an Arduino, via the Matlab Arduino
   % toolbox.
   %
   %
   
   properties
      
   end
   
   properties (SetAccess = protected)
      
      % The arduino object
      arduino;
   end
   
   methods
      
      % Arguments are ultimately passed to openDevice
      function self = dotsWritableDOutArduino()
         
         self = self@dotsWritableDOut();
         
         persistent theArduino
         
         if isempty(theArduino)
             theArduino = arduino();
         end
         
         % Initialize the Arduino object -- certainly can add arguments
         % to find it if we want to get trickier
         self.arduino = theArduino;
      end
      
      % Write to a single digital output channel
      %
      % pin is string
      % value is scalar
      function timestamp = writeDigitalPin(self, pin, value)
         
         % disp(sprintf('Writing value = <%.2f> to pin <%s>', value, pin))
         self.arduino.writeDigitalPin(pin, value);
         timestamp = feval(self.clockFunction);
      end
      
      % Write to a multiple digital output channels at once
      %
      % pin is cell array of strings
      % value is vector
      function timestamp = writeDigitalPins(self, pins, values)
         
         for ii = 1:length(pins)
            self.arduino.writeDigitalPin(pins{ii}, values(ii));
         end
         timestamp = feval(self.clockFunction);
      end      
   end   
end
