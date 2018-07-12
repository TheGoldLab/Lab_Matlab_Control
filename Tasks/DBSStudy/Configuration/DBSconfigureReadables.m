function DBSconfigureReadables(mainTreeNode, datatub)
% function DBSconfigureReadables(mainTreeNode, datatub)
%
% configuration routine for dotsReadable classes
%
% Separated from DBSconfigure for readability
%
% 5/28/18 created by jig

%% ---- Try to use the named input device as primary input
if strncmp(datatub{'Settings'}{'userInput'}, 'dotsReadableEye', length('dotsReadableEye'))
   
   % Get the object
   ui = eval(datatub{'Settings'}{'userInput'});
   
   % Set properties: filename, screenEnsemble for calibration drawing, autoread
   [~, name, ~] = fileparts(datatub{'Settings'}{'filename'});
   ui.filename = sprintf('%s_eye', name);
   ui.filepath = fullfile(getDataFilepath('DBSStudy'), 'Pupil');
   ui.screenEnsemble = datatub{'Graphics'}{'screenEnsemble'};
   ui.recordDuringCalibration = true;
   ui.queryDuringCalibration = false;
   ui.doShowEye = false;
   
   % Add it to the mainTreeNode (for possible GUI control)
   mainTreeNode.runGUIArgs = {ui};
   
   % Start: calibration, recording
   addCall(datatub{'Control'}{'startCallList'}, {@calibrate, ui}, 'calibrate eye');
   addCall(datatub{'Control'}{'startCallList'}, {@record, ui, true}, 'start recording eye');
   
   % Finish: calibration, recording (done in reverse order)
   addCall(datatub{'Control'}{'finishCallList'}, {@close, ui}, 'close eye');
   addCall(datatub{'Control'}{'finishCallList'}, {@record, ui, false}, 'finish recording eye');
   
else
   
   % Use utility to find the appropriate keyboard for this machine
   ui = getMatchingKeyboard();
   
   % Add a maintask finish fevalable to close the kb
   addCall(datatub{'Control'}{'finishCallList'}, {@close, ui}, 'close keyboard');
end

%% ---- Save to the tub
ui.isAutoRead = true;
datatub{'Control'}{'userInputDevice'} = ui;
