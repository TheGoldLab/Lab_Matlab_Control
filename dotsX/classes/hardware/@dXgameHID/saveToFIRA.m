function g_ = saveToFIRA(g_)
%saveToFIRA method for class dXgameHID: copy data to FIRA data record
%   g_ = saveToFIRA(g_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Save method for class dXgameHID.
%-% Called by loop at the end of a trial to
%-%   write current values to FIRA
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXgameHID

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% call buildFIRA_addTrial to add the data to the current
% (last) trial in FIRA

buildFIRA_addTrial(g_.FIRAdataType, {g_.values});