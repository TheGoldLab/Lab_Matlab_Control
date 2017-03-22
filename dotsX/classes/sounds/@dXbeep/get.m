function val_ = get(b, propertyName)
%get method for class dXbeep: query property values
%   val_ = get(b, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded get method for class dXbeep
%-% get the value of a particular property from
%-% the specified dXbeep object
%----------Special comments-----------------------------------------------
%
%   See also get dXbeep

% Copyright 2004 by Joshua I. Gold

% just return the value of the given fieldname
val_ = b(1).(propertyName);