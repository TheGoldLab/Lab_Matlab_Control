%% Begin Task
clear all, close all;

%Create calibration task
[task, list] = CalibrationTaskXST(0, []);

%Run task 
dotsTheScreen.openWindow();
task.run;
dotsTheScreen.closeWindow();

%% Post Processing
%Getting synchronized times
%Sorting/manipulating data that requires Tobii connection
Data.EyeTime = list{'Eye'}{'RawTime'};
Data.EyeTime = int64(Data.EyeTime);
 
for i = 1:length(Data.EyeTime)
Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
end

list{'Eye'}{'Time'} = Data.EyeTime;

% Putting list items in data structure

%DAQ pulse times
Data.SynchTimes = list{'Synch'}{'Times'}; %If the eeglog file is ever mistakenly overwritten, you can recover synch data here.

%Assorted Timestamps
Data.DrawTimestamps = list{'Timestamps'}{'Drawing'};
Data.ChangeTimestamps = list{'Timestamps'}{'Change'};
Data.ReactionTimes = list{'Timestamps'}{'ReactionTime'};
Data.TrialStartTimes = list{'Timestamps'}{'TrialStart'};

%Eyetracker related times
Data.RawTime = list{'Eye'}{'RawTime'};
Data.LeftEye = list{'Eye'}{'Left'};
Data.RightEye = list{'Eye'}{'Right'}; 

%Calib point coordinates
Data.CalibX = list{'Coordinates'}{'X'};
Data.CalibY = list{'Coordinates'}{'Y'};



%% SAVE

savename = list{'Subject'}{'Savename'};
synchtimes = list{'Synch'}{'Times'};

% Saving all data to a List as well as a Data Structure
save(savename, 'list');
save([savename 'DATA'], 'Data')

% Saving synch timing data as an ascii for Align-Tool
 dlmwrite('eeg.eeglog.up', synchtimes, 'precision', 20) %in MICROseconds