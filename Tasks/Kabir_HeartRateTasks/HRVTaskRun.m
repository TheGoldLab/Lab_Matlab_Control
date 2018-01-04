%% Running HRV task
[maintask, list] = HRVTask;

dotsTheScreen.openWindow
maintask.run
dotsTheScreen.closeWindow

%% Post processing
%Sorting/manipulating data that requires Tobii connection
Data.EyeTime = list{'Eye'}{'RawTime'};
Data.EyeTime = int64(Data.EyeTime);
 
for i = 1:length(Data.EyeTime)
Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
end

list{'Eye'}{'Time'} = Data.EyeTime;

%% Data structure
Data.LeftEye = list{'Eye'}{'Left'};
Data.RightEye = list{'Eye'}{'Right'};
Data.RawEyeTime = list{'Eye'}{'RawTime'};
Data.PulseIn = list{'Synch'}{'In'};
Data.PulseOut = list{'Synch'}{'Out'};
Data.Stimulus = list{'Stimulus'}{'Playlist'};
Data.StimTimes = list{'Stimulus'}{'Timestamps'};