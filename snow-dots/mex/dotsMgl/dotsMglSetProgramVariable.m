% Set the value of a shader program uniform variable.
% 
%  elementSize = dotsMglSetProgramVariable(variableInfo, value)
% 
%  variableInfo is a struct containing information about a shader program
%  uniform variable, as returned from dostMglLocateProgramVariable().
% 
%  value is a numeric value to assign to the program variable.  It must be
%  floating point, with Matlab class 'double' or 'single.  All values are
%  treated as OpenGL's 'GLfloat' type.
% 
%  value may be a scalar or matrix with up to 4 rows or columns.  If value
%  has 1 row, it is treated as a float, vec2, vec3, or vec4 GLSL variable.
%  If value has multiple rows, it is treated as a GLSL "mat" variable with
%  the corresponding number of rows and columns.  For example, if value has
%  4 columns and 3 rows, it is treated as a mat4x3 variable.
% 
%  Note that Matlab and OpenGL both use the column-major matrix ordering.
% 
%  On success, a positive elementSize, which should match the number or
%  columns times the numbe of rows of value.
% 
%  Although GLSL supports arrays of float, vec, and mat variables, 
%  dotsMglSetProgramVariable() does not.
% 
%  17 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglSetProgramVariable.c.

