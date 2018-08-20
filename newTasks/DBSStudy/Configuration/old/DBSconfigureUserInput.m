function DBSconfigureUserInput(datatub)
% function DBSconfigureUserInput(datatub)
%
% configuration routine for dotsReadable classes
%
% Separated from DBSconfigure for readability
%
% 5/28/18 created by jig

%% ---- Always use a keyboard for control commands entered between trials
%
% Get the keyboard
kb = DBSmatchingKeyboard();

% Add a maintask finish fevalable to close the kb
addCall(datatub{'Control'}{'finishCallList'}, {@close, kb}, 'close keyboard');

%% ---- Try to use tne named input device as primary input
if strcmp(datatub{'Input'}{'uiDevice'}, 'dotsReadableEyePupilLabs') || ...
      strcmp(datatub{'Input'}{'uiDevice'}, 'dotsReadableEyeMouseSimulator')
   
   % Get the pupl labs eye tracking object
   ui = eval(datatub{'Input'}{'uiDevice'});
   
   % Make sure it's working
   if ~ui.isAvailable
      ui = dotsReadableEyeMouseSimulator();
   end
      
   % Add the screenEnsemble for calibration drawing
   ui.screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
   
   % Set up the eye position monitor
   ui.openGazeMonitor();
   
   % Set the pupil data file match the topsDataLog file, with _pupilLabs suffix
   [~, name, ~] = fileparts(datatub{'Input'}{'fileName'});
   ui.filename = sprintf('%s_pupilLabs', name);
   
   % Add start/finish fevalables to the main topsTreeNode
   %  START calibration, recording
   addCall(datatub{'Control'}{'startCallList'}, {@calibrate, ui}, 'calibrate eye');
   addCall(datatub{'Control'}{'startCallList'}, {@record, ui, true}, 'start recording eye');
   
   %  Finish calibration, recording (done in reverse order)
   addCall(datatub{'Control'}{'finishCallList'}, {@close, ui}, 'close eye');   
   addCall(datatub{'Control'}{'finishCallList'}, {@record, ui, false}, 'finish recording eye');
else
   
   % Otherwise use the keyboard
   ui = kb;
end

% Set both to autoRead (read during getNextEvent calls)
%   and save to the tub
ui.isAutoRead = true;
kb.isAutoRead = true;
datatub{'Control'}{'userInputDevice'} = ui;
datatub{'Control'}{'keyboard'} = kb;

