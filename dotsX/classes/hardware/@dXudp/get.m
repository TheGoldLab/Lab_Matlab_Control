function val_ = get(u, propertyName)%get method for class dXudp: query property values
%   val_ = get(u, propertyName)%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%%-% overloaded get method for class dXudp%-% get the value of a particular property from%-% the specified dXudp object%----------Special comments-----------------------------------------------
%
%   See also get dXudp
% Copyright 2006 by Joshua I. Gold% just return the value of the given fieldnameval_ = u.(propertyName);