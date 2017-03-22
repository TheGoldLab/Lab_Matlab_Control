% Find metadata about GLSL shader program variables.
% 
%  variableInfo = dotsMglLocateProgramVariable(programInfo, ...
%   [uniformName])
% 
%  programInfo is a struct containing the OpenGL identifier and other
%  information about a shader program, as returned from
%  dotsMglCreateShaderProgram().
% 
%  uniformName is an optional string specifying the name of a shader
%  program uniform variable.  If uniformName matches the name of a uniform
%  variable used by the given shader program, returns a struct of metadata
%  for that uniform variable.
% 
%  If uniformName is omitted, returns a struct array of metadata about all
%  of the uniform variables used by the shader program.
% 
%  17 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglLocateProgramVariable.c.

