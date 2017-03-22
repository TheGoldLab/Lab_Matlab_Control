% Select ahead of time which values to capture during transform feedback.
% 
%  nSelected = dotsMglSelectTransformFeedback(programInfo, bufferInfo, varyingNames, ...
%   [elementOffsets])
% 
%  programInfo is a struct containing the OpenGL identifier and other
%  informaiton about a shader program, as returned from
%  dotsMglCreateShaderProgram().
% 
%  bufferInfo is a struct array in which each element containins the OpenGL
%  identifier and other information about a VBO, as returned
%  from dotsMglCreateVertexBufferObject.  Each VBO will receive vertex data
%  during transform feedback.
% 
%  varyingNames is a cell array of strings with a name for each VBO.
%  Each name must match the name of a varying variable in the given shader
%  program.
% 
%  varyingNames must be supplied at least once, before transform feedback.
%  When varyingNames is supplied, the given shader program will be
%  re-linked.  varyingNames may be omitted in subsequent calls, in order to
%  supply new bufferInfo without re-linking the program.
% 
%  The elementOffsets argument is an optional double array containing an
%  offset into each VBO, to use as the starting location for writing
%  feedback data.  The default offset for each VBO is 0--the first element.
%  bufferInfo fields such as elementsPerVertex are used to compute correct
%  byte offsets into each VBO.
% 
%  Note that selecting transform feedback requires insider knowledge about
%  the names and sizes of the shader program's varying variables.
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
%  dotsMglSelectTransformFeedback.c.

