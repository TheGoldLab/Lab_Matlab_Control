% Create an OpenGL vertex buffer object (VBO).
% 
%  bufferInfo = dotsMglCreateVertexBufferObject(data, ...
%   [target, usage, elementsPerVertex, elementStride])
% 
%  data is a numeric array with data to put in a VBO.  The VBO will try to
%  accomodate the size and numeric type of data.
% 
%  target is an index to specify the default OpenGL binding target for the
%  VBO.  Valid targets are:
% 
%   0   GL_ARRAY_BUFFER
%   1   GL_ELEMENT_ARRAY_BUFFER
%   2   GL_PIXEL_PACK_BUFFER
%   3   GL_PIXEL_UNPACK_BUFFER
% 
%  The default is 0.
% 
%  usage is an index to specify an OpenGL usage hint, which may help
%  OpenGL do optimization.  Valid usages are:
% 
%   0   GL_STREAM_DRAW
%   1   GL_STREAM_READ
%   2   GL_STREAM_COPY
%   3   GL_STATIC_DRAW
%   4   GL_STATIC_READ
%   5   GL_STATIC_COPY
%   6   GL_DYNAMIC_DRAW
%   7   GL_DYNAMIC_READ
%   8   GL_DYNAMIC_COPY
% 
%  The default is 0.
% 
%  elementsPerVertex specifies the data "size"--the number of numeric
%  components to use for each vertex.  For example, XYZ position or RGB
%  color data would have 3 elements per vertex.  The default is 1.
% 
%  elementStride specifies the number of elements between vertices.  For
%  example, an array with interleaved XYZRGB position and color data could
%  use a stride of 6 elements.  The default is 0, which assumes elements
%  are tightly packed.
% 
%  On success, returns a struct with contains the OpenGL identifier and
%  other information about the new VBO.
% 
%  1 September 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglCreateVertexBufferObject.c.

