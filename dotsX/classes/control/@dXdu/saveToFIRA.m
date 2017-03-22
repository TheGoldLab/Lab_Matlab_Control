function dus_ = saveToFIRA(dus_)
%saveToFIRA method for class dXdu: copy data to FIRA data record
%   saveToFIRA(dus_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded saveToFIRA method for class dXdu (down/up)
%-%
%-% Arguments:
%-%   dus_ ... array of dXdu objects
%-%
%-% Returns:
%-%   nada
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXdu

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania