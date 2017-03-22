function t_ = blank(t_)%blank method for class dXtext: hide instances
%   t_ = blank(t_)%
%   All DotsX graphics classes have blank methods.  These hide class 
%   instances by setting their visible properties to FALSE.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%%-% Overloaded blank method for class dXtext%-%%-% Just set all the visible flags to 0%----------Special comments-----------------------------------------------
%
%   See also blank dXtext
% Copyright 2004 by Joshua I. Gold%   University of Pennsylvania[t_.visible] = deal(false);