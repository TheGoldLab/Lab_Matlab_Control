function val_ = get(ta_, propertyName)
%get method for class dXtask: query property values
%   val_ = get(ta_, propertyName)
%
%   All DotsX classes have a get method which returns a specified property
%   for a class instance, or a struct containing the values of all the
%   properties of one or more instances.
%
%----------Special comments-----------------------------------------------
%-%
%-% gets named property of a task object.
%----------Special comments-----------------------------------------------
%
%   See also get dXtask

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania
    
% just return the value of the given fieldname
%   for the first object
val_ = ta_(1).(propertyName);
