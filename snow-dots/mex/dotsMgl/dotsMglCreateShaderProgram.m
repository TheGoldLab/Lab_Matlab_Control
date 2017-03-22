% Create a GLSL shader program from source strings.
% 
%  programInfo = dotsMglCreateShaderProgram(vertexSource, fragmentSource)
% 
%  vertexSource and fragmentSource are strings (char arrays), each
%  containing source code for a GLSL vertex shader or fragment shader.
%  vertexSource, fragmentSource, or both may be supplied.
% 
%  Returns programInfo, which is a struct containing the OpenGL identifier
%  and other information about a new shader program.
% 
%  If there is a compilation error, programInfo will contain debugging
%  information in the vertexLog or fragmentLog field.  If there is a
%  linking error programInfo will contain debugging information in the
%  programLog field.
% 
%  Note: dotsMglCreateShaderProgram() does not accept source strings for
%  geometry shaders, which are not generally available in OpenGL 2.0
%  contexts.  Perhaps a second function could use extensions to attach a
%  geometry shader and re-link the program.
% 
%  14 Sep 2011 created
%
%  2011 by Benjamin Heasly
%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.
%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.
%
%  This help documentation was copied from header comments in
%  dotsMglCreateShaderProgram.c.

