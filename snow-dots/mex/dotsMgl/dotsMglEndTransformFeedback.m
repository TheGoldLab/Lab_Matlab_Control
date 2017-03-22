% Stop capturing transform feedback data.
% 
%  status = dotsMglEndTransformFeedback()
% 
%  Discontinues transform feedback and restores rasterization for the
%  OpenGL pipeline.
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
%  dotsMglEndTransformFeedback.c.

