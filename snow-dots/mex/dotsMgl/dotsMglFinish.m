% Wait for OpenGL to finish processing all commands.
% 
%  dotsMglFinish()
% 
%  Exposes glFinish() behavior to Matlab.  glFinish() causes the calling
%  application (Matlab) to block until OpenGL is finished processing all
%  previous commands, such as drawing and rendering.
% 
%  dotsMglFinish() is useful for timing measurements.  Unlike mglFlush(),
%  dotsMglFinish() doesn't cause a frame buffer swap.
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglFinish.c.

