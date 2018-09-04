classdef dotsReadableHIDButtons < dotsReadableHIDKeyboard
   % @class dotsReadableHIDButtons
   %
   % Simple subclass that treats Ashwin's button box as a keyboard.
   %
   
   properties
      
      % Button names
      buttonLeft  = 'KeyboardLeftShift';
      buttonRight = 'KeyboardRightShift';
      
      % Dummy component corresponding to either button being pressed
      buttonEither = 'KeyboardSpacebar'; 
   end
   
   properties (SetAccess = protected)
      buttonLeftID;
      buttonRightID;
      buttonEitherID;
   end
   
   methods
      
      % Contstructor -- just a keyboard, really.
      function self = dotsReadableHIDButtons()
         
         devicePreference.vendorID = 1204;
         devicePreference.ProductID = 13896;
         devicePreference.PrimaryUsage = 6;
         
         self = self@dotsReadableHIDKeyboard(devicePreference);
         
         % Get the "buttonEither" component ID
         self.buttonLeftID   = self.getComponentIDbyName(self.buttonLeft);
         self.buttonRightID  = self.getComponentIDbyName(self.buttonRight);
         self.buttonEitherID = self.getComponentIDbyName(self.buttonEither);
      end
      
      
      % Overloaded utility to check for either button
      function [name, data] = getNextEvent(self, isPeek, acceptedEvents)
         
         % check arguments
         if nargin < 2
            isPeek = false;
         end
         
         if nargin < 3 || isempty(acceptedEvents)
            acceptedEvents = {};
         end
         
         % Do we need to care about checking for "either" event
         if ~isempty(self.buttonEither)
            eitherEvent = self.eventDefinitions(self.buttonEitherID).name;
            if ~isempty(eitherEvent) && self.eventDefinitions(self.buttonEitherID).isActive && ...
                  (isempty(acceptedEvents) || any(strcmp(eitherEvent, acceptedEvents)))
               
               % Save active flags
               LeftIsActive  = self.eventDefinitions(self.buttonLeftID).isActive;
               RightIsActive = self.eventDefinitions(self.buttonRightID).isActive;
               
               % Set both to active
               self.eventDefinitions(self.buttonLeftID).isActive  = true;
               self.eventDefinitions(self.buttonRightID).isActive = true;
               
               % call getNextEvent
               [name, data] = self.getNextEvent@dotsReadable(isPeek);
               
               % Check for event
               if (strcmp(name, self.eventDefinitions(self.buttonLeftID).name) && ...
                     ~LeftIsActive) || ...
                     (strcmp(name, self.eventDefinitions(self.buttonRightID).name) && ...
                     ~RightIsActive)                  
                  name = eitherEvent;
               end
               
               % Reset active flags
               self.eventDefinitions(self.buttonLeftID).isActive = LeftIsActive;
               self.eventDefinitions(self.buttonRightID).isActive = RightIsActive;
               
               % done
               return
            end
            
            % Otherwise just get the event normally
            [name, data] = self.getNextEvent@dotsReadable(isPeek, acceptedEvents);
         end
      end
   end
end