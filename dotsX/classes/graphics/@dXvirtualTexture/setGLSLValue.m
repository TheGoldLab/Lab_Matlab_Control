function vt_ = setGLSLValue(vt_, name, value)
% Set the value of a GLSL variable for a dXvirtualTexture instance
%
%   vt_ = setGLSLValue(vt_, name, value)
%
%   setGLSLValue will call the relevant GLSL function, supplied by
%   Psychtoolbox, to set a new value to the GLSL variable with the given
%   name.  This is how you can change the parameters of a virtualTexture.
%
%   vt_ is an instance of dXvirtualTexture.  It is returned to reflect
%   changes made by this method.
%
%   name is a string with the name of a GLSL variable.  The name must match
%   exactly the name of a variable defined in the GLSL program to which
%   this dXvirtualTexture is attached.
%
%   value is the new value to set to the variable.  Its size must match the
%   size declared in the GLSL program.  For example, if the program
%   declares a uniform float, then value here must be a scalar.  If the
%   program declares a uniform vec4, then the value here must be a vector
%   with 4 elements.

% copyright 2008 Benjamin Heasly at the University of Pennsylvania

% reality check
global ROOT_STRUCT
if isempty(name) || isempty(value) || ROOT_STRUCT.screenMode ~= 1
    return
end

% check to see if we already know the memory address of the named variable
if isempty(vt_.GLSLLocations) || ~isfield(name, vt_.GLSLLocations)

    % look for the named variable
    try
        loc = glGetUniformLocation(vt_.GLSLProgram, name);

        if loc < 0
            warning(sprintf('dXtexture/setGLSLValue: could not locate the variable %s in the GLSL program %d', name, vt_.GLSLProgram));
            return
        end

    catch
        warning(sprintf('dXtexture/setGLSLValue: either %d is an invalid GLSL program, or you need to open an onscreen Screen window', vt_.GLSLProgram));
        return
    end

    % found a location.  Store it by name
    vt_.GLSLLocations.(name) = loc;
end

% set the value by location and type
%   in a sec I'll come back and support more than just doubles
glUseProgram(vt_.GLSLProgram);
switch numel(value)

    case 1
        glUniform1f(vt_.GLSLLocations.(name), value(1));
    case 2
        glUniform2f(vt_.GLSLLocations.(name), value(1), value(2));
    case 3
        glUniform3f(vt_.GLSLLocations.(name), value(1), value(2), value(3));
    case 4
        glUniform4f(vt_.GLSLLocations.(name), value(1), value(2), value(3), value(4));
end
glUseProgram(0);