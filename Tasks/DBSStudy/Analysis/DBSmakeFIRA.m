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

if nargin < 1 || isempty(filename)
   % for debugging
   filename = 'data_2018_06_19_10_48.mat';
end

% Flush the data log (probably not necessary)
topsDataLog.flushAllData()

% Use the machine-specific data pathname to find the data
rawFile = fullfile(DBSfilepath(), 'Raw', filename);

% Get the ecode matrix using the topsDataLog utility
FIRA.ecodes = topsDataLog.parseEcodes('trial', rawFile);

% Get the pupil calibration data
pupilCalibration = topsDataLog.getTaggedData('dotsReadableEye calibration');

end