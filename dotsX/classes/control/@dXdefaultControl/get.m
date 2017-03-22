function val_ = get(dc, propertyName)
%get method for class dXdefaultControl: query property values
%   val_ = get(dc, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% gets named property of a dXdefaultControl object.
%----------Special comments-----------------------------------------------
%
%   See also get dXdefaultControl

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

val_ = dc(1).(propertyName);
