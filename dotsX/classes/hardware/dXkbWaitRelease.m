function [key_, time_ all_] = dXkbWaitRelease(timeout)
% function [key_, time_ all_] = dXkbWaitRelease(timeout)
%
% Get a keypress and subsequent release using the default dXkbHID class
%   and HIDx event notifications
%
% Uses pause while waiting for events.  This allows MATLAB to draw, etc.
%
% A key event looks like this: [keyCode, value, time]
%   keyCodes are found in KbName from Psychtoolbox
%   value is 1=pressed 0=released
%   time is seconds since function call, with milisecond resolution
%
% Arguments:
%   timeout ... in seconds
%
% Returns:
%   key_    ... KbName keyCode of last key released
%   time_   ... seconds since function call (ms resolution)

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

global ROOT_STRUCT

if nargin < 1 || isempty(timeout)
    timeout = 10;
end

% clear old values
ROOT_STRUCT.dXkbHID = reset(ROOT_STRUCT.dXkbHID);

% wait until key pressed
keyDown = false;
endTime = GetSecs + timeout;
while ~keyDown && (GetSecs < endTime)
    HIDx('run');
    keyEvents = get(ROOT_STRUCT.dXkbHID, 'values');
    keyDown = ~isempty(keyEvents) && any(keyEvents(:,2)==1);
	WaitSecs(.001);
end

% Check that for every press there is a release
%   This will misbehave when e.g. release Return then press it.
r = keyEvents(:,2)==0;
allReleased = sum(r) >= sum(~r) ...
    && all(ismember(keyEvents(~r,1), keyEvents(r,1)));
while ~allReleased && (GetSecs < endTime)
    HIDx('run');
    keyEvents = get(ROOT_STRUCT.dXkbHID, 'values');
    r = keyEvents(:,2)==0;
    allReleased = sum(r) >= sum(~r) ...
        && all(ismember(keyEvents(~r,1), keyEvents(r,1)));
	WaitSecs(.001);
end

if allReleased
    ii = find(r, 1, 'last');
    key_ = keyEvents(ii,1);
    if nargout > 1
        time_ = keyEvents(ii,3);
    end
    if nargout > 2
        all_ = keyEvents(r,3);
    end
else
    key_ = [];
    time_ = [];
end