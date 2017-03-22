function val_ = get(fc_, propertyName)
%get method for class dXfunctionCaller: query property values
%   val_ = get(fc_, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% gets named property of a dXfunctionCaller object.
%----------Special comments-----------------------------------------------
%
%   See also get dXfunctionCaller

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

val_ = fc_(1).(propertyName);