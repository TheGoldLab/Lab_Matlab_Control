function k_ = reset(k_, offsetTime)
%reset method for class dXkbHID: return to virgin state
%   k_ = reset(k_, start_time)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% resets a 'dXkbHID' object
%-% and returns the updated object
%----------Special comments-----------------------------------------------
%
%   See also reset dXkbHID

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

if k_.active

    % check for any keypress
    %   need to look in ROOT_STRUCT to find asynchronous events
    %   so use rGet and rSet

    % clear HID event queue and saved events
    HIDx('reset', k_.HIDIndex);
    rSet('dXkbHID', 1, 'values', []);

    HIDx('run');
    keyIsDown = ~isempty(rGet('dXkbHID', 1, 'values'));
    while keyIsDown
        disp('LET GO OF THE KEYBOARD')
        WaitSecs(0.002);
        HIDx('run');
        keyIsDown = ~isempty(rGet('dXkbHID', 1, 'values'));
        rSet('dXkbHID', 1, 'values', []);
    end

    if nargin > 1 && ~isempty(offsetTime)
        k_.offsetTime = offsetTime;
    end
    k_.values = [];
    k_.recentVal = 1;
end