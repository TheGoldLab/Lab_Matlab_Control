classdef dotsReadableEyeMouseSimulator < dotsReadableEye
   % dotsReadableEyeMouseSimulator
   %
   % Uses the mouse to simulate gaze position, for testing. Clicking the
   % button re-zeros the output
   %
   % 5/24/18 written by jig
   
   properties
      
      % The mouse object
      HIDmouse = [];

      % The mouse object component IDS (x,y,button)
      HIDmouseComponentIDs;
      
      % Scale factor.. could calibrate this if we wanted to be fancy
      mouseScaleFactor = 10;
   end
   
   %% Public method
   methods
      
      % Constructor method
      function self = dotsReadableEyeMouseSimulator(matching, frequency)
         self = self@dotsReadableEye();
         
         % get the mouse object
         if nargin < 1 || isempty(matching)            
            self.HIDmouse = dotsReadableHIDMouse();
         else
            self.HIDmouse = dotsReadableHIDMouse(matching);
         end
         
         % Get and save mouse component IDs... first two are x,y, last is
         % button press
         self.HIDmouseComponentIDs = getComponentIDs(self.HIDmouse);

         
         % set a dummy sample frequency
         if nargin < 2 || isempty(frequency)
            self.sampleFrequency = 200;
         else
            self.sampleFrequency = frequency;
         end
      end
   end
   
   %% Protected methods
   methods (Access = protected)
      
      function newData = readRawEyeData(self)
         
         % Read from the mouse
         self.HIDmouse.read();
         pause(0.001);
         
         % Check for button press
         if getValue(self.HIDmouse, self.HIDmouseComponentIDs(3))
            disp('BUTTON!')
            self.HIDmouse.flushData();
            self.HIDmouse.x = 0;
            self.HIDmouse.y = 0;
         end
         
         % save x,y values and timestamp
         time = mglGetSecs;
         newData = [ ...
            self.xID self.HIDmouse.x/self.mouseScaleFactor time; ...
            self.yID -self.HIDmouse.y/self.mouseScaleFactor time];
      end
      
      function closeDevice(self)
         
         % close the HID device
         self.HIDmouse.close();
      end
   end
end