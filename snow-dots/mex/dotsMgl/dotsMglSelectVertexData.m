% Select ahead of time which VBO data to use when drawing vertices.
% 
%  nSelected = dotsMglSelectVertexData(bufferInfo, dataNames, ...
%   [elementOffsets, isClientData])
% 
%  bufferInfo is a struct array in which each element containins the OpenGL
%  identifier and other information about a VBO, as returned
%  from dotsMglCreateVertexBufferObject.  Each VBO should contain an array
%  of vertex data.  bufferInfo fields such as elementsPerVertex and 
%  elementStride are used to locate data for each vertex within the VBO.
% 
%  dataNames is a cell array of strings.  Each element of dataNames
%  indicates the type of vertex data for the corresponding element of
%  bufferInfo.  Each element must be one of the following:
% 
%   'vertex' - data to pass to glVertexPointer()
%   'color' - data to pass to glColorPointer()
%   'secondaryColor' - data to pass to glSecondaryColorPointer()
%   'texCoord' - data to pass to glTexCoordPointer()
%   'normal' - data to pass to glNormalPointer()
%   'fogCoord' - data to pass to glFogCoordPointer()
% 
%  Other strings will be ignored.
% 
%  The elementOffsets argument is an optional double array containing an
%  offset into each VBO, to use as the starting location for reading vertex
%  data.  The default offset for each VBO is 0--the first element.
% 
%  isClientData is an optional flag which might help debugging.  If
%  isClientData is non-zero, vertex data are passed from Matlab application
%  memory instead of from OpenGL VBO memory.  isClientData should usually
%  be omitted.
% 
%  If the bufferInfo argument is missing or empty, all vertex data
%  selection is disabled.
% 
%  Returns nSelected, the number of VBOs that were successfully selected.
% 
%  23 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglSelectVertexData.c.

