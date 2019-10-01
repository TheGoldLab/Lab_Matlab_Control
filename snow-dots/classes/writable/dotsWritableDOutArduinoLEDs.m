classdef dotsWritableDOutArduinoLEDs < dotsWritableDOutArduino
   % @class dotsWritableDOutArduinoLEDs
   %
   % Show LEDs using Liana's arduino masterpiece.
   %  pins [0, 1, 2, 3, ...] are [r1, g1, b1, r2, ...]
   %
   % Created by jig from Liana Keesing's prototype
   %  July 13, 2019
   
   properties
      
      % For accessing hardware pins
      pinBase = 'A';      
   end
   
   methods
      
      % Arguments are ultimately passed to openDevice
      function self = dotsWritableDOutArduinoLEDs()
         
         % Make an arduino object
         self = self@dotsWritableDOutArduino();         
      end
      
      % Quickly turn on LED
      %
      % indexOrName is assumed to be based on Liana's 5-LED configuration:
      %  1: Right
      %  2: Top
      %  3: Center
      %  4: Left
      %  5: Bottom
      %
      % Color is 'r', 'g', 'b'
      % onOff is 0=off, 1=on, 
      %
      function timestamp = toggleLED(self, indexOrName, color, onOff)
         
         % Check for name
         if ischar(indexOrName)
            indexOrName = find(strcmpi(indexOrName, ...
               {'right', 'top', 'center', 'left', 'bottom'}));
         end
         
         % Check if turning on or off
         if nargin < 4
            onOff = 1;
         end
         
         % Check if we need to use setLEDs
         if isnumeric(color)
            if onOff == 1
               timestamp = self.setLEDs({indexOrName color});
            else
               timestamp = self.setLEDs({indexOrName 'off'});
            end
            return
         end
         
         % Get base pin index
         LEDBaseIndex = (indexOrName-1)*3;
         
         switch color
            case 'r'
               
               % RED
               timestamp = self.writeDigitalPin( ...
                  [self.pinBase int2str(LEDBaseIndex)], onOff);
               
            case 'g'
               
               % GREEN
               timestamp = self.writeDigitalPin( ...
                  [self.pinBase int2str(LEDBaseIndex+1)], onOff);
               
            case 'b'
               
               % BLUE
               timestamp = self.writeDigitalPin( ...
                  [self.pinBase int2str(LEDBaseIndex+2)], onOff);
         end         
      end
      
      % Turn on/off LED(s)
      %
      % specs is cell array of index, value pairs; e.g.,
      %  {1 'r' 2 'off' 3 'g'}
      function timestamp = setLEDs(self, specs)
         
         if nargin < 2 || length(specs) < 2
            timestamp = nan;
            return
         end
         
         % Set up args to writeDigitalPins
         % Remember each LED is associated with three pins: R,G,B
         nLEDs  = floor(length(specs)./2);
         pins   = cell(nLEDs*3, 1);
         values = nans(nLEDs*3, 1);
         for ii = 1:nLEDs
            
            % Get LED index
            LEDIndex = (specs{(ii-1)*2+1}-1)*3;
                       
            % Get base index
            baseIndex = (ii-1)*3;

            % Get pins
            pins{baseIndex+1} = [self.pinBase int2str(LEDIndex)  ];
            pins{baseIndex+2} = [self.pinBase int2str(LEDIndex+1)];
            pins{baseIndex+3} = [self.pinBase int2str(LEDIndex+2)];
            
            % Get values
            if isnumeric(specs{(ii-1)*2+2})
               
               % Given as RGB triplet
               if length(specs{(ii-1)*2+2}) == 3

                  % Given as RGB triplet
                  vals = specs{(ii-1)*2+2};                  
               else
                  
                  % Given as brightness
                  vals = repmat(specs{(ii-1)*2+2}, 1, 3);
               end               
            else
               
               switch specs{(ii-1)*2+2}
                  
                  case 'r' % RED
                     vals = [1 0 0];
                     
                  case 'g' % GREEN
                     vals = [0 1 0];
                     
                  case 'b' % BLUE
                     vals = [0 0 1];
                     
                  case 'y' % YELLOW
                     vals = [1 1 0];
                     
                  case 'c' % CYAN
                     vals = [0 1 1];
                     
                  case 'm' % MAGENTA
                     vals = [1 0 1];
                     
                  otherwise % OFF
                     vals = [0 0 0];                     
               end
            end
            
            % Set the values
            values(baseIndex+1) = vals(1);
            values(baseIndex+2) = vals(2);
            values(baseIndex+3) = vals(3);
         end
         
         % Write to the pins and get timestamp
         timestamp = self.writeDigitalPins(pins, values);         
      end    
      
      % Turn off all LEDs
      %
      function timestamp = turnOffLEDs(self, indices)
         timestamp = self.setLEDs({1 'x' 2 'x' 3 'x' 4 'x' 5 'x'});
      end
   end   
end
