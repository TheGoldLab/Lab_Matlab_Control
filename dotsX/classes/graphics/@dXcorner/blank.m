function c_ = blank(c_)%blank method for class dXcorner: hide instances
%   c_ = blank(c_)%
%   All DotsX graphics classes have blank methods.  These hide class 
%   instances by setting their visible properties to FALSE.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%%-% Overloaded blank method for class dXcorner%-%%-% Just set all the visible flags to 0%----------Special comments-----------------------------------------------
%
%   See also blank dXcorner
% Copyright 2006 by Joshua I. Gold[c_.visible] = deal(false);