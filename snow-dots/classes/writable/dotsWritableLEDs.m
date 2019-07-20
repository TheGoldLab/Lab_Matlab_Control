classdef dotsWritableLEDs < dotsWritable
   % @class dotsWritableLEDs
   %
   % Class for turning a bank of LEDs on/off
   %
   % Created by jig 07/17/2019
   
   properties
      
      % Number of available LEDs -- should be set in subclass
      numLEDs;
      
      % Specs for color (other?)
      specs;
   end
   
   methods
      
      % Arguments are ultimately passed to openDevice
      function self = dotsWritableLEDs()
         
         % Make a writable object
         self = self@dotsWritable();
      end
      
      % Set specs
      %
      % colors is cell array of [r g b] or chars
      function set(self, indices, colors)
         
         % Check args
         if nargin < 3 || isempty(colors)
            colors = 'w';
         end
                  
         if ~iscell(colors)
            
            % Just one color given
            colorCell = cell(1, length(indices));
            [colorCell{:}] = deal(colors);
            colors = colorCell;
         end
         
         % set colors
         for ii = 1:length(indices)
            % disp([indices(ii) colorRGB(colors{ii})])
            self.specs(indices(ii)).color = colorRGB(colors{ii});
         end
      end
           
      % Turn off all LEDs
      %
      function timestamp = blankLEDs(self)
         
         % Set all off
         timestamp = self.toggleLEDs({[], 1:self.numLEDs});
      end
   end   
end
