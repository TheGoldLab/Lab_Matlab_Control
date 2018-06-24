% Script for testing the dotsReadableEye class

% Get the readableEye object
e = dotsReadableEyeMouseSimulator();

% set up a small screen for calibration
dotsTheScreen.reset('displayIndex', 0);
dotsTheScreen.openWindow();

try
   
   % Run initial calibration routine
   e.calibrate();
   
   % Open the gaze monitor
   eyeGUI(topsTreeNode('test'), e);   
   
   % Don't buffer, don't recenter
   resetGaze(e, false, false);
   for ii = 1:100
      e.read();
      pause(0.1);
   end
   
   % Buffer and recenter
   resetGaze(e, true, true);
   for ii = 1:100
      e.read();
      pause(0.1);
   end
      
catch
   dotsTheScreen.closeWindow();
end