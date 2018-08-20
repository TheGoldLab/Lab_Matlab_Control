%% AudRT Task Run
clear classes; close all;

%Create task/list
[task, list] = AudRTTaskT(1, 1);

%Open window and run
dotsTheScreen.openWindow();
task.run;
dotsTheScreen.closeWindow();

%% Post processing
Data.ID = list{'Subject'}{'ID'};

%Getting synchronized times
%Sorting/manipulating data that requires Tobii connection
Data.EyeTime = list{'Eye'}{'RawTime'};
Data.EyeTime = int64(Data.EyeTime);
 
for i = 1:length(Data.EyeTime)
Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
end

list{'Eye'}{'Time'} = Data.EyeTime;

% Putting list items in data structure
Data.SynchTimes = list{'Synch'}{'Times'};
Data.RawTime = list{'Eye'}{'RawTime'};
Data.LeftEye = list{'Eye'}{'Left'};
Data.RightEye = list{'Eye'}{'Right'}; 
Data.HazardRates = list{'Stimulus'}{'Hazards'};
Data.StateList = list{'Stimulus'}{'Statelist'};
Data.Choices = list{'Input'}{'Choices'};
Data.ChoiceTimes = list{'Timestamps'}{'Choices'};


