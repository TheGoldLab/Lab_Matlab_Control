function [data, unit, time] = J17Read(num_samples, leave_open, no_open, PORT)
% function [data, unit, time] = J17Read(num_samples, leave_open, no_open, PORT)
%
% Read data over RS-232D from the J17 lumacolor handheld light meter.
%   [data, unit, time] = J17Read(num_samples, leave_open, no_open, PORT)
%
%   A little function to communicate with the Tektronix J17 LumaColor
%   photometer.  Opens a serial connection with SerialComm.mexmac (or
%   .mexmaci), which sould be in Psychtoolbox/PsychHardware.
%
%   Hard codes several parameters since, like, who else is gonna use this?
%   Plus, you might as well edit this file anyway, if the parameters are
%   going to change.  The "executable" is the same as the config file.
%
%   In:
%       num_samples ... # of measurements for J17 to read and return
%                       (default 1).
%       leave_open  ... boolean leave open the serial port (like, during
%                       successive readings) (default false).
%       no_open     ... boolean don't reopen the serial port (like, during
%                       successive readings) (default false).
%       PORT        ... # COM port where is the J17 connected (default 2).
%
%   Out:
%       data        ... double array measurements (or nan), 1xnum_samples
%       unit        ... cell array of unit strings reported by J17
%       time        ... Psychtoolbox GetSecs time when each sample was
%                       read, relative to inital query time.
%
%   See Tektrinox J17 LumaColor manual section 3-47
%
%   See also pause clock SerialComm

% Copyright 2006 by Benjamin Heasly, University of Pennsylvania

% least surprising default: one measurement
if ~nargin || isempty(num_samples)
    num_samples = 1;
end

if nargin < 2 || isempty(leave_open)
    leave_open = false;
end

if nargin < 3 || isempty(no_open)
    no_open = false;
end

% will this ever change?  usb-serial adaptor on COM2 port?
if nargin < 4 || isempty(PORT)
    PORT = 2;
end

% parameters for SerialComm
CONFIG = '2400,n,8,1'; % '19200,n,8,1';
%PORT = 2;
EOL = sprintf('\n');
N = 10;
HSHAKE = 's'; %'h' 's' 'n'
% SerialComm knows how to:
%   SerialComm( 'open', PORT, CONFIG);
%   str = SerialComm( 'readl', PORT, EOL);
%   str = SerialComm( 'read', PORT, N);
%   SerialComm( 'write', PORT, command);
%   SerialComm( 'purge', PORT);
%   SerialComm( 'hshake', PORT, HSHAKE);
%   SerialComm( 'break', PORT);
%   SerialComm( 'close', PORT);
%   SerialComm( 'status', PORT);

% Symbols to send out to the J17:
BEGIN   = '!';
END     = sprintf('\n');
REPORT  = 'NEW';
% the NEW command may take an argument, the number of samples to report at once.
%   1-127 is number of samples
%   128-255 is continuous sampling until another command
num_at_once = 1;
command = sprintf('%s%s %d%s',BEGIN,REPORT,num_at_once,END);

% allocate returns
unit = cell(1, num_samples);
data = nan*ones(1, num_samples);
time = nan*ones(1, num_samples);

% reading takes a bit of time
interval = .7;
if ~leave_open && num_samples > 0
    disp(sprintf('reading %d samples from J17 will take ~%.1fs', ...
        num_samples, num_samples*interval));
end

% start SerialComm with J17 on COM2 port
if ~no_open
    SerialComm('open', PORT, CONFIG);
end

try
    SerialComm( 'purge', PORT);
    know = GetSecs;
    returns = 0;
    tries = 0;
    while returns < num_samples && tries < 10*num_samples

        % trigger one report at a time from the J17
        s = SerialComm('write', PORT, command);

        % empirically, this seems like a good round trip time
        pause(interval)

        % read the return data
        str = SerialComm( 'readl', PORT, EOL);
        tries = tries + 1;

        % decode data if it's here
        if ~isempty(str)
            returns = returns + 1;
            [u, n] = strtok(str);
            unit{returns} = u;
            data(returns) = str2double(n);
            time(returns) = GetSecs-know;
        end
    end

    % free the serial/mex resources
    if ~leave_open
        SerialComm('close', PORT);
    end
catch
    disp('J17Serial: to err is lumen')

    % free the serial/mex resources
    SerialComm('close', PORT);
    e = lasterror;
    e.message
end