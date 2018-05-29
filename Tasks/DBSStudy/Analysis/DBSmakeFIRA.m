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
   filename = 'data_2018_05_29_09_25.mat';
end

% Flush the data log (probably not necessary)
topsDataLog.flushAllData()

% Use the machine-specific data pathname to find the data
pathname = DBSfilepath();

% Get the ecode matrix using the topsDataLog utility
FIRA.ecodes = topsDataLog.parseEcodes( 'trial', ...
   fullfile(pathname, 'Raw', filename));

% Get the pupil data

end