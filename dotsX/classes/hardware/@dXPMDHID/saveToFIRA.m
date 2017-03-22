function p_ = saveToFIRA(p_)
%saveToFIRA method for class dXPMDHID: copy data to FIRA data record
%   p_ = saveToFIRA(p_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% SaveToFIRA method for class dXPMDHID.
%-% Called by dXtask/trial at the end of a trial to
%-%   copy current values to FIRA
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXPMDHID

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% call buildFIRA_addTrial to add the data to the current
% (last) trial in FIRA
% update times using offsetTime
if ~isempty(p_.values)
    p_.values(:,3) = p_.values(:,3) + p_.startScanTime;
end

buildFIRA_addTrial(p_.FIRAdataType, {p_.values});