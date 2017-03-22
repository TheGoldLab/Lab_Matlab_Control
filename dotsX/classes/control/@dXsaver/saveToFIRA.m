function sas_ = save(sas_)
%saveToFIRA method for class dXsaver: copy data to FIRA data record
%   sas_ = save(sas_)
%
%   Many non-graphics DotsX classes can copy important data to FIRA, a
%   a global data record accompanied by analysis tools.
%
%   Some classes, such as hardware classes, return updated instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Save (to FIRA) method for class saver
%-%
%-% Arguments:
%-%   sas_ ... array of saver objects
%-%
%-% Returns:
%-%   sas_ ... the array of objects (not changed here, but in
%-%               principle could be)
%----------Special comments-----------------------------------------------
%
%   See also saveToFIRA dXsaver

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

