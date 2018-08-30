classdef dotsReadableHIDButtons < dotsReadableHIDKeyboard
    % @class dotsReadableHIDButtons
    
    properties
    end
    
    methods
        
        % Contstructor -- just a keyboard, really.
        function self = dotsReadableHIDButtons()
            
            devicePreference.vendorID = 1204;
            devicePreference.ProductID = 13896;
            devicePreference.PrimaryUsage = 6;

            self = self@dotsReadableHIDKeyboard(devicePreference);
            
        end
    
        % Overloaded utility to ensure always active
      function setEventsActiveFlag(self, activateList, deactivateList)
      end
      
        % Overloaded utility to check for either button
        function [name, data] = getNextEvent(self, isPeek, acceptedEvents)
            
            [name, data] = self.getNextEvent@dotsReadable();
            
            if ~isempty(name) && strcmp(acceptedEvents, 'holdFixation')
                name = 'holdFixation';
            end
        end
        
        %
    end    
end