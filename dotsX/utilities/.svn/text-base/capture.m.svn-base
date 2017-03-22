function capture(demo, logfile)
%
% adds some silly, overloaded messaging function to the MATLAB path, then
% executes the given command, probably a demo script.  They will store UDP
% messages in the given file, rather than sending them to a remote machine.

% get some kind of real
if ~nargin || isempty(demo) || ~ischar(demo)
    return
end

global fid time

% get the location of overloaded message functions
[thisPath, name, ext, ver] = fileparts(mfilename('fullpath'));
capturePath = [thisPath,'/messageCapture'];

if nargin < 2 || isemptu(logfile) || ~ischar(logfile)
    % this is a fine default
    logfile = 'messageLog.m';
end
log = fullfile(thisPath, logfile);

try
    % open a file for logging, put handle in global variable
    fid = fopen(log, 'w');
    fprintf(fid, ['%% Message dump from ', demo, ':\n%%  ',datestr(now),'\n\n%% rInit(''remote'');\n\n']);

    % put overloaded message functions on top of the path
    addpath(capturePath);

    % run a demo, capturing any messages
    %   and recorfing time stamps
    disp(['running ', demo, ' and capturing messages'])
    disp('you might need to press a key...')
    time = GetSecs;
    eval(demo)

    % restore the path to sanity
    rmpath(capturePath);
catch
    % there was an error!
    % dont forget to restore the path
    rmpath(capturePath);
end