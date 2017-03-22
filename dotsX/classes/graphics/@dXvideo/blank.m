function v_ = blank(v_)
%blank method for class dXvideo: hide instances
%   v_ = blank(v_)
%
%   All DotsX graphics classes have blank methods.  These hide class
%   instances by setting their visible properties to FALSE.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Overloaded blank method for class dXvideo
%-%
%-% Just sets all the visible flags to false.
%----------Special comments-----------------------------------------------
%
%   See also blank dXvideo

% Copyright 2008 by Benjamin Heasly at University of Pennsylvania

[v_.visible] = deal(false);