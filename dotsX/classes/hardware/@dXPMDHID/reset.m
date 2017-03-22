function p_ = reset(p_, offsetTime)
%reset method for class dXPMDHID: return to virgin state
%   p_ = reset(p_, start_time)
%
%   Some DotsX classes can revert to a consistent state, as though just
%   created, with their reset methods.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% resets a dXPMDHID object
%-% and returns the updated object
%----------Special comments-----------------------------------------------
%
%   See also reset dXPMDHID

% Copyright 2007 by Benjamin Heasly
%   University of Pennsylvania

% flush old channel events
if p_.active

    % stop scanning
    if ~isempty(p_.stopID) && ~isempty(p_.stopReport) ...
            && isa(p_.stopReport, 'uint8')
        HIDx('setReport', p_.HIDIndex, p_.stopID, p_.stopReport);
    end

    HIDx('reset', p_.HIDIndex);
    p_.values = [];
    p_.recentVal = 1;

    % restart scanning
    if ~isempty(p_.startID) && ~isempty(p_.startReport) ...
            && isa(p_.startReport, 'uint8')
        HIDx('setReport', p_.HIDIndex, p_.startID, p_.startReport);
        
        % try to align the zero of PMD data serial numbers
        p_.startScanTime = GetSecs;
    end
end

if nargin > 1 && ~isempty(offsetTime)
    p_.offsetTime = offsetTime;
end