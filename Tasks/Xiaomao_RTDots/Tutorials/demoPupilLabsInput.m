%% demoPupilLabsInput
%  
% This function demonstrates how PupilLabs can be used to determine the
% subjects response in a psychophysics task. We will initiate the
% mPupilLabs object and run a calibration for both the PupilLabs software
% as well as SnowDots. After which, we will present a cue for a short
% duration. A short message will be printed depending on whether the
% subject fixated on the cue.
%
% 11/9/17  xd  wrote it

clear all; close all;
%% Initialize mPupilLabs
mPupilLabs.init();

%% Run calibration
% 
% We need to first calibrate the PupilLabs software so that it can track
% eye positions properly. Afterwards, we will calibrate it with SnowDots so
% that we can map PupilLabs positions to screen positions with relative
% accuracy.

% Calibrate PupilLabs
mPupilLabs.calibrate();

% Calibrate to snowdots. Need to first open a SnowDots window and then call
% the calibration routine.
displayInfo = mglDescribeDisplays();
sc = dotsTheScreen.theObject();
sc.distance = 60;
sc.width  = displayInfo(2).screenSizeMM(1)/10; % Need units to be cm
sc.height = displayInfo(2).screenSizeMM(2)/10;
sc.displayIndex = 2;
sc.openWindow();

calibrateSnowdotsToPupilLabs();

%% Prepare SnowDots stimulus
%
% Create a fixation cross in the middle of the screen.
fixationCue = dotsDrawableTargets();
fixationCue.xCenter = [0 0];
fixationCue.yCenter = [0 0];
fixationCue.width   = [1 0.1] * 1;
fixationCue.height  = [0.1 1] * 1;
dotsDrawable.drawFrame({fixationCue});
pause(2);

%% Read data and print status
%
% We will read data from PupilLabs for 1 sec. Afterwards, we will check to
% see whether 95% of the gaze data is within 5 dva of the fixation spot.

% Refresh the connection so we only get live data.
mPupilLabs.refresh();

% Record start time
t0 = mPupilLabs.getTime();

% Initialize variables
t = 0;
allPos = zeros(1000,2);
counter = 1;

% Loop and collect data until 1 sec has passed.
while t - t0 < 1
    data = mPupilLabs.getGazeData();
    pos = cell2num(cell(data.norm_pos));
    pos = convertPupilLabsToSnowDotsCoord(pos);

    allPos(counter,:) = pos;
    t = data.timestamp;
    counter = counter + 1;
end

% Clear empty entries
allPos(counter:end,:) = [];

% Calculate how many data points are within desired radius
dist = sum(allPos.^2,2) < 25;
fixate = sum(dist)/length(dist) > 0.95;

% Output result
disp('Fixation: ');
disp(fixate);

sc.closeWindow();


