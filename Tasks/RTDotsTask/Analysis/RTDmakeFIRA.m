function RTDmakeFIRA(filename)
% function RTDmakeFIRA(filename)
%
% RTD = Response-Time Dots
%
% Make a FIRA data struct from the raw/pupil data. Uses the trial data
% structure defined in RTDconfigure to determine the data columns (names
% and types) then fills in the data for each structure found (rows of the
% ecodes.data matrix)
%
% Created 5/26/18 by jig

if nargin < 1 || isempty(filename)
   % for debugging
   filename = 'data_2018_05_27_18_32.mat';
end

% Flush the data log (probably not necessary)
topsDataLog.flushAllData()

% Use the machine-specific data pathname to find the data
pathname = RTDfilepath();

% Get the ecode matrix using the topsDataLog utility
FIRA.ecodes = topsDataLog.parseEcodes( 'trial', ...
   fullfile(pathname, 'Raw', filename));

% Get the pupil data

end