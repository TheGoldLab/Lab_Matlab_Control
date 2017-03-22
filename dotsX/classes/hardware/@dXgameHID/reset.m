function g_ = reset(g_, offsetTime)
%reset method for class dXgameHID: return to virgin state
%   g_ = reset(g_, offsetTime)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% resets a dXgameHID object
%-% and returns the updated object
%----------Special comments-----------------------------------------------
%
%   See also reset dXgameHID

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

if g_.active

    % check for any keypress
    %   need to look in ROOT_STRUCT to find asynchronous events
    %   so use rGet and rSet

    % clear HID event queue and saved events
    HIDx('reset', g_.HIDIndex);
    rSet('dXgameHID', 1, 'values', []);

    HIDx('run');
    buttonDown = ~isempty(rGet('dXgameHID', 1, 'values'));
    while buttonDown
        disp('LET GO OF THE GAMEPAD')
        WaitSecs(0.002);
        HIDx('run');
        buttonDown = ~isempty(rGet('dXgameHID', 1, 'values'));
        rSet('dXgameHID', 1, 'values', []);
    end

    if nargin > 1 && ~isempty(offsetTime)
        g_.offsetTime = offsetTime;
    end
    g_.values = [];
    g_.recentVal = 1;
end