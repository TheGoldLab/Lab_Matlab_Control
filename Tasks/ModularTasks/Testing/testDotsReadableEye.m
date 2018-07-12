% Script for testing the dotsReadableEye class

try
   
   % Get the readableEye object
   %e = dotsReadableEyePupilLabs();
   %e = dotsReadableEyeMouseSimulator();
   % e = dotsReadableEyeEyelink();
  e = dotsReadableEyePupilLabs();
  
   % set up a small screen for calibration
   e.screenEnsemble = makeScreenEnsemble(false, 0);
   e.screenEnsemble.callObjectMethod(@open);
   
   % Run initial calibration routine
   e.calibrate();
   
  % e.calibrate('s');
    
   dotsTheScreen.closeWindow();
   %    % Open the gaze monitor
   %    eyeGUI(topsTreeNode('test'), e);
   %
   %    % Don't buffer, don't recenter
   %    resetGaze(e, false, false);
   %    for ii = 1:100
   %       e.read();
   %       pause(0.1);
   %    end
   %
   %    % Buffer and recenter
   %    resetGaze(e, true, true);
   %    for ii = 1:100
   %       e.read();
   %       pause(0.1);
   %    end
   
catch
   dotsTheScreen.closeWindow();
end