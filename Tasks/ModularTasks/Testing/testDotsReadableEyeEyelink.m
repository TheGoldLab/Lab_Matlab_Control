% Script for testing the dotsReadableEyeEyelink class

% set up a small screen for calibration
screenEnsemble = makeScreenEnsemble(false, 0);
screenEnsemble.callObjectMethod(@open);

% Get the readableEye object
e = dotsReadableEyeEyelink();

% give it the screen ensemble
e.screenEnsemble = screenEnsemble;

% Run initial calibration routine
e.calibrate();
   
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