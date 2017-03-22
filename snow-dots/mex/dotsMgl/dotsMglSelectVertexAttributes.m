% Select ahead of time VBOs to use as generic vertex attributes.
%  
%  nSelected = dotsMglSelectVertexAttributes(programInfo, bufferInfo, attribNames, ...
%   [elementOffsets, isNormalized])
% 
%  programInfo is a struct containing the OpenGL identifier and other 
%  informaiton about a shader program, as returned from 
%  dotsMglCreateShaderProgram().
% 
%  bufferInfo is a struct array in which each element containins the OpenGL
%  identifier and other information about a VBO, as returned
%  from dotsMglCreateVertexBufferObject.  Each VBO should contain an array
%  of generic vertex attribute data.  bufferInfo fields such as 
%  elementsPerVertex and elementStride are used to locate attribute data 
%  for each vertex within the VBO.
% 
%  attribNames is a cell array of strings with a name for each of the VBOs.
%  Each name must match the name of a vertex attribute variable in the 
%  given shader program.
%  
%  attribNames must be supplied at least once, before drawing.  When 
%  attribNames is supplied, the given shader program will be re-linked.
%  attribNames may be omitted in subsequent calls, in order to supply new
%  bufferInfo without re-linking the program.
% 
%  The elementOffsets argument is an optional double array containing an
%  offset into each VBO, to use as the starting location for reading vertex
%  data.  The default offset for each VBO is 0--the first element.
% 
%  The isNormalized argument is an optional double array specifying
%  whether to normalize integer data for each VBO.  Where
%  isNormalizedBuffer is non-zero, the VBO data be normalized.  Where
%  isNormalizedBuffer is zero, or if isNormalizedBuffer is omitted, VBO
%  data will not be normalized.
% 
%  If the programInfo or bufferInfo argument is missing or empty, all
%  generic vertex attributes numbered 1 and above will be disabled.
% 
%  Note that generic vertex attribute 0 corresponds to vertex position and
%  the "gl_Vertex" shader variable.  dotsMglSelectVertexAttributes
%  ignores attribute 0.
% 
%  Returns nSelected, the number of VBOs that were successfully selected.
% 
%  24 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglSelectVertexAttributes.c.

