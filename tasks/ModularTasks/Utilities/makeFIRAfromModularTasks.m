function FIRA = makeFIRAfromModularTasks(filename, studyTag)
% function FIRA = makeFIRAfromModularTasks(filename, studyTag)
%
% Make a FIRA data struct from the raw/pupil data of a set of modular tasks
%
% Calls topsDataLog.parseEcodes, which assumes that the tag 'trial' corresponds
%  to a trial data structure in the topsDataLog.
%
% Created 5/26/18 by jig

%% Parse filename, studyTag
%
% Give defaults for debugging
if nargin < 1 || isempty(filename)
   filename = 'data_2018_08_08_08_55';   
end

if nargin < 2 || isempty(studyTag)
   studyTag = 'DBSStudy';
end

% Flush the data log
topsDataLog.flushAllData();

% Use the machine-specific data pathname to find the data
filepath = fullfile(dotsTheMachineConfiguration.getDefaultValue('dataPath'), studyTag);
rawFile  = fullfile(filepath, 'topsDataLog',  [filename '.mat']);
uiFile   = fullfile(filepath, 'dotsReadable', [filename '_eye']);

%% Get the ecode matrix using the topsDataLog utility
%
% get the mainTreeNode
mainTreeNodeStruct = topsDataLog.getTaggedData('mainTreeNode', rawFile);
mainTreeNode = mainTreeNodeStruct.item;

% Now read the ecodes -- note that this works only if the trial struct was
% made only with SCALAR entries
FIRA.ecodes = topsDataLog.parseEcodes('trial');

%% Get the gaze data
%
% Use constructor class static method to read the data file.
%
% for PupilLabs: Uses a python script...
ui = mainTreeNode.uiObjects{1};
[eyeData, tags] = feval([class(ui) '.readDataFromFile'], uiFile);
eyeData = cell2num(eyeData);

%% Synchronize timing
%
% Get the number of trials
numTrials = size(FIRA.ecodes.data, 1);
   
% Get indices of columns, by name
%
% indices of columns with local/screen/ui start times
tli = find(strcmp(FIRA.ecodes.name, 'time_local_trialStart'), 1);
tui = find(strcmp(FIRA.ecodes.name, 'time_ui_trialStart'), 1);
tsi = find(strcmp(FIRA.ecodes.name, 'time_screen_trialStart'), 1);

% indices of times in screen reference frame
sfi = find(strcmp(FIRA.ecodes.name, 'time_fixOn'), 1);
sgis = cat(2, ...
   find(strcmp(FIRA.ecodes.name, 'time_targsOn'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_dotsOn'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_targsOff'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_fixOff'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_dotsOff'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_fdbkOn'), 1));

% indices of times in ui reference frame
uci = find(strcmp(FIRA.ecodes.name, 'time_choice'), 1);

% get data indices
eti = find(strcmp(tags, 'time'));
exi = find(strcmp(tags, 'gaze_x'));
eyi = find(strcmp(tags, 'gaze_y'));
eci = find(strcmp(tags, 'confidence'));

% Analog data
eyeData(:,eti) = syncAnalogTimes(eyeData(:,eti), FIRA.ecodes.data(:,[tli tui]));

% Ecodes are all encoded with respect to fixaton onset
wrtTimes = FIRA.ecodes.data(:, sfi);

% Ecodes collected in screen time
FIRA.ecodes.data(:,sgis) = FIRA.ecodes.data(:,sgis) - repmat(wrtTimes, 1, numel(sgis));

% Ecodes collected in ui time (here just choice)
FIRA.ecodes.data(:,uci) = (FIRA.ecodes.data(:,uci) - FIRA.ecodes.data(:,tui)) - ...
   (wrtTimes - FIRA.ecodes.data(:,tsi));

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
FIRA.analog = struct(     ...
        'name',         {tags}, ... % 1xn" cell array of strings
        'acquire_rate', [],   ... % 1xn array of #'s, in Hz 
        'store_rate',   round(1/median(diff(eyeData(:,1)))),   ... % 1xn" array of #'s, in Hz
        'error',        {{}}, ... % mx1  array of error messages
        'data',         {cell(numTrials,1)});      % mxn" cell array

% Get list of local start times
localTrialStartTimes = [FIRA.ecodes.data(:,tli); inf];

for tt = 1:numTrials
   
   % Get gaze data
   Lgaze = eyeData(:,eti) >= localTrialStartTimes(tt) & ...
      eyeData(:,eti) < localTrialStartTimes(tt+1);
   
   % Put eye data in order: time, x, y, confidence and in local time
   FIRA.analog.data{tt} = eyeData(Lgaze, [eti exi eyi eci]);

   % Calibrate timestamps   
   FIRA.analog.data{tt}(:,1) = (FIRA.analog.data{tt}(:,1) - FIRA.ecodes.data(tt,tli)) - ...
      (wrtTimes(tt) - FIRA.ecodes.data(tt,tsi));
end
% 
% %% Plot stuff
% %
% for tt = 1:numTrials
%    
%    cla reset; hold on;
%    xax = FIRA.analog.data{tt}(:,1);
%    plot(xax, FIRA.analog.data{tt}(:,2), 'ko-');
%    plot(xax, FIRA.analog.data{tt}(:,3), 'ro-');
%    if size(FIRA.analog.data{tt}, 2) >= 4
%       Llo = FIRA.analog.data{tt}(:,4) < 0.7;
%       plot(xax(Llo), FIRA.analog.data{tt}((Llo),2), 'kx');
%       plot(xax(Llo), FIRA.analog.data{tt}((Llo),3), 'rx');
%    end
%    
%    % Show fpoff, RT
%    rti = find(strcmp(FIRA.ecodes.name, 'RT'), 1);
%    if ecodes.data(tt,1) <= 2
%       refTime = FIRA.ecodes.data(tt,sgis(4)); % Fix off for VGS/MGS
%    else
%       refTime = FIRA.ecodes.data(tt,sgis(2)); % Dots on
%    end
%    plot([0 0], [-5 5], 'k--');
%    plot(FIRA.ecodes.data(tt,sgis(1)).*[1 1], [-5 5], 'c-'); % trgs on
%    plot(refTime.*[1 1], [-5 5], 'b-'); % fp off/dots on
%    plot(FIRA.ecodes.data(tt,uci).*[1 1]+.01, [-5 5], 'm-'); % choice
%    plot((refTime+FIRA.ecodes.data(tt,rti)).*[1 1], [-5 5], 'g-'); % RT
%    plot(FIRA.ecodes.data(tt,sgis(5)).*[1 1], [-5 5], 'b--'); % dots off
%    
%    ylim([-10 10])
%    r = input('next')
% end

