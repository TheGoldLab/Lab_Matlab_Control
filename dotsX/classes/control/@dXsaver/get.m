function val_ = get(sa_, propertyName)
%get method for class dXsaver: query property values
%   val_ = get(sa_, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% gets named property of a saver object.
%----------Special comments-----------------------------------------------
%
%   See also get dXsaver

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

val_ = sa_(1).(propertyName);
