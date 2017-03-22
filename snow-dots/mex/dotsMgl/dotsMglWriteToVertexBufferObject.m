% Write data to an OpenGL vertex buffer object (VBO) or a sub-range.
% 
%  nElements = dotsMglWriteToVertexBufferObject(bufferInfo, data, ...
%   [offsetElements, doReallocate])
% 
%  bufferInfo is a struct with contains the OpenGL identifier and other
%  information about a VBO, as returned from
%  dotsMglCreateVertexBufferObject().
% 
%  data is a numeric array containing data elements to write to the VBO.
%  The numeric type of data should match the numeric type of the VBO.
% 
%  offsetElements and nElements are optional, used to speciy a sub-range
%  within the VBO.  "Elements" are in units that agree with the  VBO's
%  numeric type, such as double, single, or int32.  One element may contain
%  multiple bytes.
% 
%  offsetElements specifies where to start writing data elements.  The
%  default is 0--the first element.
% 
%  doReallocate is an optional flag specifying whether or not to "orphan"
%  the VBO data store before writing.  Orphaning might improve performance
%  in some cases by allowing OpenGL to allocate a new data store for the
%  VBO intead of synchonizing access to the original data store.  The
%  default is 0, don't reallocate.
% 
%  On success, returns nElements, the number of elements written to the
%  VBO.  nElements should match numel(data).
% 
%  Note: dotsMglWriteToVertexBufferObject uses glMapBuffer() to write VBO
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
%  dotsMglWriteToVertexBufferObject.c.

