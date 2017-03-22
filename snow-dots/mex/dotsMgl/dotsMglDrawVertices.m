% Draw vertices from data and attributes selected ahead of time.
% 
%  nVertices = dotsMglDrawVertices(primitive, nVertices,
%   [vertexOffset, pointSize, eboInfo])
% 
%  Draw vertices from buffered data and attributes which were chosen ahead
%  of time with dotsMglSelectVertexData() or 
%  dotsMglSelectVertexAttributes().
% 
%  primitive is an index specifying which OpenGL drawing mode to use.
%  Valid primitives are:
% 
%   0   GL_POINTS
%   1   GL_LINE_STRIP
%   2   GL_LINE_LOOP
%   3   GL_LINES
%   4   GL_TRIANGLE_STRIP
%   5   GL_TRIANGLE_FAN
%   6   GL_TRIANGLES
%   7   GL_QUAD_STRIP
%   8   GL_QUADS
%   9   GL_POLYGON
% 
%  The default is 0.
% 
%  nVertices is the nubmer of vertices to draw.  The vertex data and
%  attributes which were selected ahead of time must contain at least this
%  many vertices.  Otherwise, Matlab might crash.
% 
%  vertexOffset is an optional offset into the data and attributes which
%  were selected ahead of time, specifying the first vertex to draw.  The
%  default offset is 0--the first vertex.
% 
%  pointSize is an optional value specifying the size in pixels of each
%  point drawn when primitive = 0.
% 
%  eboInfo is an optional struct containing the OpenGL identifier and
%  other information about a a buffer object, as returned from
%  dotsMglCreateVertexBufferObject.  This buffer object is treated as an
%  "element buffer object".  It must contain unsigned integer data and each
%  integer is treated as the index of a vertex.  This allows drawing of
%  non-sequential vertices from among the data and attributes which were
%  selected ahead of time.
% 
%  If eboInfo is provided, nVertices and vertexOffset refer to vertex 
%  indices, instead of vertex data and attributes.
% 
%  Note: eboInfo allows dotsMglDrawVertices() to invoke glDrawElements()
%  instead of glDrawArrays().  This may allow OpenGL to optimize things
%  like vertex sharing and caching.
% 
%  Returns the number of vertices drawn, which should match the given
%  nVertices.
% 
%  23 September 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglDrawVertices.c.

