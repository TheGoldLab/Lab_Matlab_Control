%% Connect to Tracker

close all
clear classes

disp('Initializing Tobii Eye Tracker\n');
tetio_init();

% Set to tracker ID to the product ID of the tracker you want to connect to.
trackerId = 'XL060-31500295.local.';
fprintf('Connecting to tracker "%s"...\n', trackerId);
tetio_connectTracker(trackerId);

currentFrameRate = tetio_getFrameRate;
fprintf('Eye Tracker Frame Rate: %d Hz.\n', currentFrameRate);

%% Begin Calibration
clear all, close all;

%Create calibration task
[task, list] = CalibrationTaskXST(0, []);

%Export variables from task for use
Calib = list{'Calib'}{'Calib'};
mOrder = list{'Calib'}{'mOrder'};

%Track status to make sure eyes are positioned properly
TrackStatus;

try
    %Run task + Calibration
    tetio_startCalib;
    
    dotsTheScreen.openWindow();
    task.run;
    dotsTheScreen.closeWindow();
    
    %Compute calib. This may throw an error if there's not enough eyedata
    tetio_computeCalib;
    
    calibPlotData = tetio_getCalibPlotData;
    
    %Plot the calibration points to check if calib was ok
    pts = PlotCalibrationPoints(calibPlotData, Calib, mOrder);
    
    tetio_stopCalib;

catch ME    %  Calibration failed
        tetio_stopCalib;
        h = input('Not enough calibration data. Do you want to try again([y]/n):','s');
        if isempty(h) || strcmp(h(1),'y')
            close all;            
            continue; 
        else
            return;    
        end
        
end

%% Start tracking for the experiment
tetio_startTracking;

%% Post Processing


%% SAVE

savename = list{'Subject'}{'Savename'};
synchtimes = list{'Synch'}{'Times'};

% Saving all data to a List as well as a Data Structure
save(savename, 'list');

% Saving synch timing data as an ascii for Align-Tool
 dlmwrite('eeg.eeglog.up', synchtimes, 'precision', 20) %in MICROseconds