%dreamOddballRun
clear all, close all;

Screen('Preference','SkipSyncTests', 1);
[subID, EDFfilename] = MKEyelinkCalibrate();

%%

[task, list] = dreamOddballConfig_Eyelink(0,0,0, subID);
%First argument is whether distractor is on(1) or off(0),
%Second argument is whether adapative difficulty is on(1) or off(0),
%Third argument is whether button is pressed for odd frequencies (0) or for
%standard frequencies(1)

dotsTheScreen.openWindow();
task.run
dotsTheScreen.closeWindow();

%% Saving Eyelink Data File
%Close file, stop recording
    Eyelink('StopRecording');
    Eyelink('Command','set_idle_mode');%new
    WaitSecs(0.5);%new
    Priority();
    Eyelink('CloseFile');

    try
        fprintf('Receiving data file ''%s''\n', EDFfilename );
        status=Eyelink('ReceiveFile', EDFfilename);
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(EDFfilename, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', EDFfilename, pwd );
        end
    catch rdf
        fprintf('Problem receiving data file ''%s''\n', EDFfilename );
        rdf;
    end


%% Post-Processing

Data.StandardFreq = list{'Stimulus'}{'StandardFreq'};
Data.OddFreq = list{'Stimulus'}{'OddFreq'};
Data.ProbabilityOdd = list{'Stimulus'}{'ProbabilityOdd'};
Data.ResponsePattern = list{'Input'}{'ResponsePattern'}; % buttons to press 
Data.MotorEffort = list{'Input'}{'Effort'};
Data.StimTimestampsOne = list{'Stimulus'}{'Playtimes'}; %Store sound player timestamps (in seconds)
Data.StimTimestampsTwo = list{'Stimulus'}{'PlaytimesTwo'};
Data.EyelinkTimestamps = list{'Eyelink'}{'Timestamps'};  %Store eyelink timestamps (in milliseconds)
Data.EyelinkInterval = list{'Eyelink'}{'Interval'}; % Delay to get the timestamps of the eyetracker (in seconds)
Data.StimFrequencies = list{'Stimulus'}{'Playfreqs'};% Store whether the trial triggered a standard sound or an oddball
Data.Choices = list{'Input'}{'Choices'}; %Storing if subject pressed the buttons required (if they press another set of buttons, value=0)>
Data.Corrects = list{'Input'}{'Corrects'}; %Storing correctness of answers (1= true, 0=false). Initialized to 33 so we know if there was no input during a trial with 33.
Data.ChoiceTimestamps = list{'Timestamps'}{'Response'}; %Storing subject response timestamp


% --> To know if the task required to press the buttons for the oddballs
% (0) or the standard sounds (1) as referred initialy in the call of the 
% dreamOddballConfig_Eyelink function (third argument), refer to these
% arguments in the list: list{'Input'}{'OppositeOn'}.
% Similarly to know if the distractors were on: list{'Distractor'}{'On'}
% And if the adaptive difficulty was on: list{'Input'}{'AdaptiveOn'}

%% Saving

save([list{'Subject'}{'Savename'} '.mat'],'list')
save([ list{'Subject'}{'Savename'} '_Data' '.mat'], 'Data') 

Eyelink('Shutdown');