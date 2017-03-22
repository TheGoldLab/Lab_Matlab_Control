function val_ = get(d, propertyName)%get method for class dXdots: query property values
%   val_ = get(d, propertyName)%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%%-% Overloaded get method for class dXdots%-% get the value of a particular property from%-% the specified dXdots object%----------Special comments-----------------------------------------------
%
%   See also get dXdots
% Copyright 2004 by Joshua I. Gold% just return the value of the given fieldnameval_ = d(1).(propertyName);