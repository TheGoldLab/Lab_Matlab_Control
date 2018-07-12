% Script for testing the dotsReadableEyeEyelink class

% Get the readableEye object
e = dotsReadableEyeEyelink();

if ~e.isAvailable
    disp('ERROR')
end

% give it the screen ensemble
e.screenEnsemble = makeScreenEnsemble(false, 1);
e.screenEnsemble.callObjectMethod(@open);

% Run initial calibration routine
e.calibrate();
   
dotsTheScreen.closeWindow();
% try showEye
% e.calibrate('s');

% try
%    
%    % Run initial calibration routine
%    e.calibrate();
%    
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
%       
% catch
%    dotsTheScreen.closeWindow();
% end