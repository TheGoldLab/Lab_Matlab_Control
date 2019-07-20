classdef dotsWritableLEDsArduino < dotsWritableLEDs
   % @class dotsWritableLEDsArduino
   %
   % Class for turning a bank of LEDs on/off using Liana's Magical Arduino
   % Controller. LEDs are each controlled by RGB triplet, starting at 0
   %
   % Created by jig 07/17/2019
   
   properties
      
   end
   
   properties (SetAccess = protected)
      
      % The Arduino
      arduino;
      
      % For accessing hardware pins
      pinBase = 'A';
   end
   
   methods
      
      %% Constructor
      %
      function self = dotsWritableLEDsArduino(numLEDs)
         
         % Make a writable objecte
         self = self@dotsWritableLEDs();
         
         % Set up defaults
         if nargin < 1
            numLEDs = 5;
         end
         self.numLEDs = numLEDs;
         self.specs = struct('color', cell(numLEDs,1));
         
         % Get an arduino object
         self.arduino = dotsWritableDOutArduino();
         
         % Set colors to white by default
         self.set(1:numLEDs);
      end
      
      %% Turn on/off LED(s)
      %
      % indices is {[on] [off]}
      function timestamp = toggleLEDs(self, indices)
         
         % Turn on
         for ii = indices{1}
            
            % Get base pin index
            LEDBaseIndex = (ii-1)*3;
            
            % Get color
            color = self.specs(ii).color;
            if isempty(color)
               color = [1 1 1];
            end
            
            % Set only for r,b,g values>0
            for jj = 1:3
               if color(jj)>0
                  timestamp = self.arduino.writeDigitalPin( ...
                     [self.pinBase int2str(LEDBaseIndex+jj-1)], color(jj));
               end
            end
         end
         
         % Turn off
         for ii = indices{2}
            
            % Get base pin index
            LEDBaseIndex = (ii-1)*3;
            
            self.arduino.writeDigitalPin([self.pinBase int2str(LEDBaseIndex  )], 0);
            self.arduino.writeDigitalPin([self.pinBase int2str(LEDBaseIndex+1)], 0);
            timestamp = self.arduino.writeDigitalPin([self.pinBase int2str(LEDBaseIndex+2)], 0);
         end         
      end
   end
end
