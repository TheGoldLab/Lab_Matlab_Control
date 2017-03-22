function e_ = eq(t1, t2)%eq method for class dXtargets: check for equivalent instances
%   e_ = eq(t1, t2)%
%   Some DotsX classes have eq methods which compare all the properties of
%   two instances to determine whether they are equivalent.
%
%   Returns boolean TRUE if instances are equivalent, FALSE if not.
%
%----------Special comments-----------------------------------------------
%-%%-% Overloaded eq method for class dXtarget%----------Special comments-----------------------------------------------
%
%   See also eq dXtargets
% written 8/28/03 by jigif length(t1.x) == length(t2.x) & ...	prod(t1.x == t2.x) & ...	length(t1.y) == length(t2.y) & ...	prod(t1.y == t2.y) & ...	length(t1.diameter) == length(t2.diameter) & ...	prod(t1.diameter == t2.diameter) & ...	length(t1.color) == length(t2.color) & ...	prod(t1.color == t2.color) & ...	t1.visible == t2.visible		e_ = true;else	e_ = false;end