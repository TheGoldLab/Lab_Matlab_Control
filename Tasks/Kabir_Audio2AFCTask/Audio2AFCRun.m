[task list] = Audio2AFC(); %Input argument is trial #. 

dotsTheScreen.openWindow()
task.run
dotsTheScreen.closeWindow();

%% Post-Processing
savename = list{'Subject'}{'Savename'};
save(savename, 'list');

%Sorting/manipulating data that requires Tobii connection
Data.EyeTime = list{'Eye'}{'RawTime'}; %Raw unsynched timestamps
Data.EyeTime = int64(Data.EyeTime);
 
for i = 1:length(Data.EyeTime)
Data.EyeTime(i) = tetio_remoteToLocalTime(Data.EyeTime(i));
end

list{'Eye'}{'Time'} = Data.EyeTime; %Synched timestamps for every sample of eyedata (in usecs).

%For the eyedata below,
%First column are X-Coordinates. Second is Y-Coordinates. 
%Third column is pupil diameter. 
%Fourth column is validity code (don't worry too much about this)
Data.LEye = list{'Eye'}{'Left'}; 
Data.REye = list{'Eye'}{'Right'};

Data.Playtimes = list{'Timestamps'}{'Stimulus'}*1e6; %in usecs

Data.Choices = list{'Input'}{'Choices'}; %Choices from user signifying left/right
Data.Choicetimes = list{'Timestamps'}{'Choices'}*1e6; %in usecs

Data.Metahazard = list{'Stimulus'}{'Metahazard'}; %The metahazard used to switch between hazard rates
Data.Hazards = list{'Stimulus'}{'Hazards'}; %The set of hazard rates used
Data.Statelist = list{'Stimulus'}{'Statelist'}; %Which hazard rate was being used during which trial
Data.Dists = list{'Stimulus'}{'Dists'}; %Set of probability distributions used
Data.Distlist = list{'Stimulus'}{'Distlist'}; %1 means first distribution, 2 means second
Data.Directionlist = list{'Stimulus'}{'Directionlist'}; %1 means left, 2 means right

save(['Data_' savename], 'Data'); %Secondary, redundant save