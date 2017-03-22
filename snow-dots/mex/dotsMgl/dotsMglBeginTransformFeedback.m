% Start capturing transform feedback data from subsequent drawing.
% 
%  status = dotsMglBeginTransformFeedback(primitive, doDiscard)
% 
%  primitive is an index hinting at which OpenGL drawing mode will be used
%  during drawing.  This primitive must agree with the primitive passed to
%  dotsMglDrawVertices.  Valid primitives are:
% 
%   0   GL_POINTS
%   3   GL_LINES
%   6   GL_TRIANGLES
% 
%  The default is 0.  The value 3 accomodates several "line" drawing modes
%  such as lines and line loops.  The value 6 accomodates several
%  "triangle" modes, such as triangles, triangle strips, quads, and quad
%  strips.
% 
%  doDiscard is an optional flag specifying whether or not to truncate the
%  OpenGL rendering pipeline.  If doDiscard is nonzero, rasterization is
%  discarded and nothing will show up on the screen.  The default is to
%  allow rasterization so that graphics will appear as usual.
% 
%  On success, returns a non-negative status number.
% 
%  Transform feedback is not supported in all OpenGL 2.0 contexts.  This 
%  function relies on the GL_EXT_transform_feedback extension and returns 
%  immediately if the extension is not found.
% 
%  21 Sep 2011 implemented
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglBeginTransformFeedback.c.

