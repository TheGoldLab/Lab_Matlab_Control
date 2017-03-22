function val_ = get(k, propertyName)%get method for class dXkbHID: query property values
%   val_ = get(k, propertyName)%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%%-% overloaded get function for class dXkbHID%-% get the value of a particular property from%-% the specified target object%----------Special comments-----------------------------------------------
%
%   See also get dXkbHID
% Copyright 2005 by Joshua I. Gold%   University of Pennsylvania% just return the value of the given fieldname%   for the first objectval_ = k.(propertyName);