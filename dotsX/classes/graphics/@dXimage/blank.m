function i_ = blank(i_)%blank method for class dXimage: hide instances
%   i_ = blank(i_)%
%   All DotsX graphics classes have blank methods.  These hide class 
%   instances by setting their visible properties to FALSE.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%%-% Overloaded blank method for class dXimage%-%%-% Just set all the visible flags to 0%----------Special comments-----------------------------------------------
%
%   See also blank dXimage
% Copyright 2006 by Joshua I. Gold[i_.visible] = deal(false);