function DBSmakeFIRA(filename)
% function DBSmakeFIRA(filename)
%
% Make a FIRA data struct from the raw/pupil data of a DBS experiment. 
%
% Calls topsDataLog.parseEcodes, which uses the trial data structure 
%  defined in DBSconfigureTasks to determine the data column names then 
%  fills in the data for each structure found (rows of the ecodes.data matrix)
%
% Created 5/26/18 by jig

%% Parse filenames
if nargin < 1 || isempty(filename)
   % for debugging
   % filename = 'data_2018_06_19_10_48';
   filename = 'data_2018_06_24_16_21';
end

% Use the machine-specific data pathname to find the data
rawFile = fullfile(DBSfilepath(), 'Raw', [filename '.mat']);

%% Get the ecode matrix using the topsDataLog utility
%
% First flush the data log
topsDataLog.flushAllData();

% get the datatub
datatubStruct = topsDataLog.getTaggedData('datatub', rawFile);

% Now read the ecodes -- note that this works only if the trial struct was
% made only with SCALAR entries
ecodes = topsDataLog.parseEcodes('trial');

% Get the number of trials
numTrials = size(ecodes.data, 1);
   
% Get indices of columns, by name
%
% indices of columns with local/screen/ui start times
tli = find(strcmp(ecodes.name, 'time_local_trialStart'), 1);
tui = find(strcmp(ecodes.name, 'time_ui_trialStart'), 1);
tsi = find(strcmp(ecodes.name, 'time_screen_trialStart'), 1);

% indices of times in screen reference frame
sfi = find(strcmp(ecodes.name, 'time_fixOn'), 1);
sgis = cat(2, ...
   find(strcmp(ecodes.name, 'time_targsOn'), 1), ...
   find(strcmp(ecodes.name, 'time_dotsOn'), 1), ...
   find(strcmp(ecodes.name, 'time_targsOff'), 1), ...
   find(strcmp(ecodes.name, 'time_fixOff'), 1), ...
   find(strcmp(ecodes.name, 'time_dotsOff'), 1), ...
   find(strcmp(ecodes.name, 'time_fdbkOn'), 1));

% indices of times in ui reference frame
uci = find(strcmp(ecodes.name, 'time_choice'), 1);

%% Get the gaze data
%
% get ui device
groupMap = datatubStruct.item.allGroupsMap('Control');
ui = groupMap('userInputDevice');
fileWithPath = fullfile(DBSfilepath(), 'Pupil', [filename '_eye']);

% Use constructor class static method to read the data file.
%
% for PupilLabs: Uses a python script... BE PATIENT!!!
[eyeData, tags] = feval([class(ui) '.readDataFromFile'], fileWithPath);

% FOR DEBUGGING
% load('tmp_pupil_data');
% dataStruct = cat(1, [gaze_positions{:}]);
% pos = [dataStruct.norm_pos];
% eyeData = [ ...
%    [dataStruct.timestamp]', ...
%    pos(1:2:end)', pos(2:2:end)', ...
%    [dataStruct.confidence]',];
% tags = {'time', 'gaze_x', 'gaze_y', 'confidence'};
% numSamples = size(eyeData, 1);

% get data indices
eti = find(strcmp(tags, 'time'));
exi = find(strcmp(tags, 'gaze_x'));
eyi = find(strcmp(tags, 'gaze_y'));
eci = find(strcmp(tags, 'confidence'));

%% Convert timestamps to local time
%
% Analog data
eyeData(:,eti) = syncAnalogTimes(eyeData(:,eti), ecodes.data(:,[tli tui]));

% Ecodes are all encoded with respect to fixaton onset
wrtTimes = ecodes.data(:, sfi);

% Ecodes collected in screen time
ecodes.data(:,sgis) = ecodes.data(:,sgis) - repmat(wrtTimes, 1, numel(sgis));

% Ecodes collected in ui time (here just choice)
ecodes.data(:,uci) = (ecodes.data(:,uci) - ecodes.data(:,tui)) - ...
   (wrtTimes - ecodes.data(:,tsi));

%% Get the pupil calibration data. Each item is:
%  1. timestamp
%  2. xyOffset
%  3. xyScale
%  4. rotation matrix
pupilCalibration = topsDataLog.getTaggedData('dotsReadableEye calibration');

if ~isempty(pupilCalibration)   

   % expects time, gx, gy
   eyeData(:,[eti exi eyi]) = dotsReadableEye.calibrateGazeSets( ...
      eyeData(:,[eti exi eyi]), pupilCalibration);
end

%% Collect trial-wise data
%
% For each trial (row in ecodes), make a cell array of pupil data
%  timestamp, gaze x, gaze y, confidence, and re-code time wrt to fp onset.
%  Also put everything in local time, wrt fp onset
trialData = cell(numTrials, 1);

% Get list of local start times
localTrialStartTimes = [ecodes.data(:,tli); inf];

for tt = 1:numTrials
   
   % Get gaze data
   Lgaze = eyeData(:,eti) >= localTrialStartTimes(tt) & ...
      eyeData(:,eti) < localTrialStartTimes(tt+1);
   
   % Put eye data in order: time, x, y, confidence and in local time
   trialData{tt} = eyeData(Lgaze, [eti exi eyi eci]);

   % Calibrate timestamps   
   trialData{tt}(:,1) = (trialData{tt}(:,1) - ecodes.data(tt,tli)) - ...
      (wrtTimes(tt) - ecodes.data(tt,tsi));
end

%% Plot stuff
%
for tt = 1:numTrials
   
   cla reset; hold on;
   xax = trialData{tt}(:,1);
   plot(xax, trialData{tt}(:,2), 'ko-');
   plot(xax, trialData{tt}(:,3), 'ro-');
   if size(trialData{tt}, 2) >= 4
      Llo = trialData{tt}(:,4) < 0.7;
      plot(xax(Llo), trialData{tt}((Llo),2), 'kx');
      plot(xax(Llo), trialData{tt}((Llo),3), 'rx');
   end
   
   % Show fpoff, RT
   rti = find(strcmp(ecodes.name, 'RT'), 1);
   if ecodes.data(tt,1) <= 2
      refTime = ecodes.data(tt,sgis(4)); % Fix off for VGS/MGS
   else
      refTime = ecodes.data(tt,sgis(2)); % Dots on
   end
   plot([0 0], [-5 5], 'k--');
   plot(ecodes.data(tt,sgis(1)).*[1 1], [-5 5], 'c-'); % trgs on
   plot(refTime.*[1 1], [-5 5], 'b-'); % fp off/dots on
   plot(ecodes.data(tt,uci).*[1 1]+.01, [-5 5], 'm-'); % choice
   plot((refTime+ecodes.data(tt,rti)).*[1 1], [-5 5], 'g-'); % RT
   plot(ecodes.data(tt,sgis(5)).*[1 1], [-5 5], 'b--'); % dots off
   
   ylim([-10 10])
   r = input('next')
end

