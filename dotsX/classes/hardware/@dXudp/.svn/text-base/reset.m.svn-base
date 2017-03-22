function u_ = reset(u_, varargin)
%reset method for class dXudp: return to virgin state
%   u_ = reset(u_, varargin)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Generally, quartz clocks will drift by about 1 microsecond per second.
%-% BSH measured 34microseconds per second drift between Mac Pro and Mac
%-% Mini Intel machines.  This means a full milisecond of skew every 30
%-% seconds, and this is too much!
%-%
%-% So, remeasure remote clock skew every trial (reset() called in
%-% dXstate/loop) to minimize clock drifting.  If reset() every 5 seconds,
%-% skew should remain below 100 microseconds.
%-%
%----------Special comments-----------------------------------------------
%
%   See also reset dXudp

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania
global ROOT_STRUCT

% clear all existing timestamps from socket buffer
while ~isempty(getMsg)
    WaitSecs(.002);
end

% the rest is for a server in remote mode
if ROOT_STRUCT.screenMode~=2
    return
end

% Send empty messages to client so that it will return timestamps. If the
% messaging round trip was fast, accept the time stamp as accurate and
% compute the intersystem time skew.
round_trip = 100;
timestamp = nan;
tries = 0;
while round_trip > 0.0025 && tries <= u_.retry
    
    start_time = GetSecs;

    % request a timestamp from client
    sendMsg('%%timestamp, please%%');

    % poll like mad for the timestamp return message
    noStuck = 10000;
    while ~matlabUDP('check') && noStuck
        WaitSecs(.0005);
        noStuck = noStuck-1;
    end

    round_trip = GetSecs - start_time;
    tries = tries+1;

    if ~noStuck
        rDisplayError('dXudp/reset is not getting return messages', ...
            true, true);
    end

    % get return string
    msg = matlabUDP('receive');
    
    % take a CPU breather
    WaitSecs(0.002);
end

% convert timestamp to double
timestamp = sscanf(msg, '%f');

% By definition, the current skew-corrected timestamp is the local time
ROOT_STRUCT.remoteTimestamp = start_time;

% Save new offset for future skew correction of remote times
ROOT_STRUCT.remoteTimeOffset = start_time - (timestamp - round_trip/2);

if tries >= u_.retry
    % show error, play error message, and throw an error bomb
    rDisplayError('dXudp/reset detected slow communications', true, true);
end