classdef dotsReadableHIDButtons < dotsReadableHIDKeyboard
   % @class dotsReadableHIDButtons
   %
   % Simple subclass for a button box that maps button presses to keyboard
   % presses
   %
   
   properties 
   end
   
   methods
      
      % Contstructor -- just a keyboard, really.
      function self = dotsReadableHIDButtons()
         
         mexHID('initialize');
         infoStruct = mexHID('summarizeDevices');
         
         if any([infoStruct.VendorID] == 1240)
            
            % Try for Black Box Toolbox first
            devicePreference.vendorID = 1240;
            devicePreference.ProductID = 1;
            devicePreference.PrimaryUsage = 6;
            
         elseif any([infoStruct.ProductID] == 13896)
            
            % Next try the custom button box
            devicePreference.vendorID = 1204;
            devicePreference.ProductID = 13896;
            devicePreference.PrimaryUsage = 6;
            
         else
            
            % Whatevs
            devicePreference.PrimaryUsage = 6;
         end
         
         % Get the device
         self = self@dotsReadableHIDKeyboard(devicePreference);
         
         % Check that we got it
         if strcmp(self.deviceInfo.Product, 'BBTK Response Box')
            
            % Found Black Box, use it to map component names
            buttons = {'KeyboardD' 'KeyboardK' 'KeyboardReturnOrEnter' 'KeyboardSpacebar'};
            
         else % NEED CHECK HERE strcmp(self.deviceInfo.Product, 'BBTK Response Box')
            
            % Found Custom Button Box, use it to map component names
            buttons = {'KeyboardShiftLeft' 'KeyboardShiftRight'};
         end
         
         % Get the list of component names
         names = {self.components.name};
         
         % Loop through the buttons
         for bb = 1:length(buttons)
            
            % Find the component
            Lcomponent = strcmp(buttons{bb}, names);
            if sum(Lcomponent) == 1
               
               % Update the name
               self.components(Lcomponent).name = ['Button' int2str(bb)];
            end
         end
      end
   end
   
   methods (Static)
      
      % For testing
      function [didHappen, waitTime] = waitForButton(buttonNumber, maxWait)
         
         % Make a button object
         btn = dotsReadableHIDButtons();
         
         % Parse args
         if nargin < 1 || isempty(buttonNumber)
            buttonNumber = 1;
         end
         
         if nargin < 2 || isempty(maxWait)
            maxWait = 10;
         end
         
         % Wait for press
         [didHappen, waitTime] = dotsReadableHIDKeyboard.waitForKeyPress(btn, ...
            ['Button' int2str(buttonNumber)], maxWait);
      end
   end
end

