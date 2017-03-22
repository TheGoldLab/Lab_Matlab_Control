% Read data from an OpenGL vertex buffer object (VBO) or a sub-range.
% 
%  data = dotsMglReadFromVertexBufferObject(bufferInfo, ...
%   [offsetElements, nElements])
% 
%  bufferInfo is a struct with contains the OpenGL identifier and other
%  information about a VBO, as returned from
%  dotsMglCreateVertexBufferObject().
% 
%  offsetElements and nElements are optional, used to speciy a sub-range of
%  data within the VBO.  "Elements" are in units that agree with the  VBO's 
%  numeric type, such as double, single, or int32.  One element may contain
%  multiple bytes.
%  
%  offsetElements specifies where to start reading data elements.  The 
%  default is 0--the first element.
%  
%  nElements specifies the number of number of elements to read, starting 
%  at the offset.  The default is all of the elements from the offset to
%  the end of the VBO.
% 
%  On success, returns data, a numeric array which contains the elements of 
%  the VBO or the specified sub-range.
% 
%  Note: dotsMglReadFromVertexBufferObject uses glMapBuffer() to read VBO 
%  data.  glMapBufferRange() might privide better performance, but it's not
%  generally available to OpenGL 2.0 contexts.
% 
%  2 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglReadFromVertexBufferObject.c.

