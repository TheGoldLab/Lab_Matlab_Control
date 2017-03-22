% Get the value of a shader program uniform variable.
% 
%  value = dotsMglGetProgramVariable(variableInfo)
% 
%  variableInfo is a struct containing information about a shader program
%  uniform variable, as returned from dostMglLocateProgramVariable().
% 
%  Returns value, the current value of the shader uniform variable.  Value
%  is always returned as a Matlab double matrix.
% 
%  value may be a scalar or matrix with up to 4 rows or columns.  If the
%  uniform variable is a GLSL float, vec2, vec3, or vec4, value will have
%  1 row.  If the variable is a GLSL "mat", value will have the
%  corresponding number of rows and columns.  For example, if the variable
%  is a mat4x3, value will have 4 columns and 3 rows.
% 
%  Note that Matlab and OpenGL both use the column-major matrix ordering.
% 
%  Although GLSL supports arrays of float, vec, and mat variables,
%  dotsMglGetProgramVariable() does not.
% 
%  17 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglGetProgramVariable.c.

