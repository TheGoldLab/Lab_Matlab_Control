%% Begin Task
clear all, close all;

%Create calibration task
[task, list] = CalibrationTaskXST(0, []);

%Run task 
dotsTheScreen.openWindow();
task.run;
dotsTheScreen.closeWindow();

%% Post Processing


%% SAVE

savename = list{'Subject'}{'Savename'};
synchtimes = list{'Synch'}{'Times'};

% Saving all data to a List as well as a Data Structure
save(savename, 'list');

% Saving synch timing data as an ascii for Align-Tool
 dlmwrite('eeg.eeglog.up', synchtimes, 'precision', 20) %in MICROseconds