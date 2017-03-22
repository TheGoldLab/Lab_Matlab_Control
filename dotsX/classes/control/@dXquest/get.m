function val_ = get(q_, propertyName)
%get method for class dXquest: query property values
%   val_ = get(q_, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% gets named property of one dXquest instance.
%----------Special comments-----------------------------------------------
%
%   See also get dXquest

% Copyright 2006 by Benjamin Heasly
%   University of Pennsylvania

val_ = q_(1).(propertyName);
