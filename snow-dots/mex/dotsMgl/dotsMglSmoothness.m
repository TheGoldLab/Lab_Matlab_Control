% Toggle OpenGL switches related to "smoothness" of graphics.
% 
%  dotsMglSmoothness(whichSwitch, isOn)
% 
%  whichSwitch is a string specifying which kind of smoothness to toggle.
%  whichSwitch may be one of the following:
% 
%   'points' - alpha blending and and "nicest" points available
%   'lines' - alpha blending and and "nicest" lines available
%   'polygons' - alpha blending and and "nicest" polygons available
%   'textures' - linear interpolation for 1D, 2D, and rectangular textures
%   'scene' - alpha blending and full scene antialiasing by multisampling
% 
%  isOn is a flag specifying whether smoothness should be turned on or off.
% 
%  The exact meaning of smoothness depends on the OpenGL software and
%  hardware being used.  In some casess, toggling a smoothness switch may
%  have no effect.
% 
%  19 Aug 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglSmoothness.c.

