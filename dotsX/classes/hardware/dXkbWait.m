function [key_, time_] = dXkbWait(timeout)
% function [key_, time_] = dXkbWait(timeout)
%
% Get a keypress using the default dXkbHID class
%   and HIDx event notifications
%
% Arguments:
%   timeout ... in seconds
%
% Returns:
%   key_    ... KbName keyCode of first key pressed
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

if keyDown
    ii = find(keyEvents(:,2)==1, 1);
    key_ = keyEvents(ii,1);
    if nargout > 1
        time_ = keyEvents(ii,3);
    end
    if nargout > 2
        all_ = keyEvents(keyEvents(:,2)==1,3);
    end
else
    key_ = [];
    time_ = [];
end