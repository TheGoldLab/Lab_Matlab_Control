% Script for testing the dotsReadableEye class

% Get the readableEye object
e = dotsReadableEyeMouseSimulator();

% set up a small screen for calibration
dotsTheScreen.reset('displayIndex', 0);
dotsTheScreen.openWindow();

try
   e.calibrate();
   
   eyeGUI(topsTreeNode('test'), e);   
   % e.openGazeMonitor();
   
   % Don't buffer, don't recenter
   resetGaze(self, false, false);
   for ii = 1:100
      e.read();
      pause(0.01);
   end
   
   % Buffer and recenter
   resetGaze(self, true, true);
   for ii = 1:100
      e.read();
      pause(0.01);
   end
   e.updateGazeMonitor();
      
catch
   dotsTheScreen.closeWindow();
end