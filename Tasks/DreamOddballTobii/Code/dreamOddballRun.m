%dreamOddballRun
clear all; close all;

[task, list] = dreamOddballConfig(0,1,0);

dotsTheScreen.openWindow();
task.run
dotsTheScreen.closeWindow();

%% Post processing
%Getting synchronized times
%Sorting/manipulating data that requires Tobii connection
Data.EyeTime = list{'Eye'}{'RawTime'};
Data.EyeTime = int64(Data.EyeTime);
 
for i = 1:length(Data.EyeTime)
Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
end

list{'Eye'}{'Time'} = Data.EyeTime;

%% Saving data
