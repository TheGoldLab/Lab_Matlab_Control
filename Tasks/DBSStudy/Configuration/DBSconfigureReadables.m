function DBSconfigureReadables(topNode)
% function DBSconfigureReadables(topNode)
%
% configuration routine for dotsReadable classes
%
% Separated from DBSconfigure for readability
%
% Arguments:
%  topNode ... the topsTreeNode at the top of the hierarchy
%
% 5/28/18 created by jig

%% ---- Use the named input device as primary input
ui = eval(topNode.nodeData{'Settings'}{'userInput'});

% always add close call
topNode.addCall('finish', {@close, ui}, 'close ui');

% always read when checking
ui.isAutoRead = true;

% Special configuration for eye trackers
if isa(ui, 'dotsReadableEye')
   
   % Set properties: filename, screenEnsemble for calibration drawing, autoread
   [path, name, ~] = fileparts(topNode.nodeData{'Settings'}{'filename'});
   ui.filename = sprintf('%s_eye', name);
   ui.filepath = fullfile(path(1:find(path==filesep,1,'last')-1), 'Pupil');
   ui.screenEnsemble = topNode.nodeData{'Graphics'}{'screenEnsemble'};
   ui.recordDuringCalibration = true;
   ui.queryDuringCalibration = false;
   ui.doShowEye = false;
   ui.useExistingCalibration = true;
   
   % Add it to the mainTreeNode (for possible GUI control)
   topNode.runGUIArgs = {ui};
   
   % Start: calibration, recording
   topNode.addCall('start', {@calibrate, ui}, 'calibrate eye');
   topNode.addCall('start', {@record, ui, true}, 'start recording eye');
   
   % Finish: calibration, recording (done in reverse order)
   topNode.addCall('finish', {@record, ui, false}, 'finish recording eye');   
end

%% ---- Save to the nodeData list
topNode.nodeData{'Control'}{'userInputDevice'} = ui;
