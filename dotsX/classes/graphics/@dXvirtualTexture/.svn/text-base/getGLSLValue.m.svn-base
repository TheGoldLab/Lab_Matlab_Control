function [vt_, val_] = getGLSLValue(vt_, name)
% Get the value of a GLSL variable for a dXvirtualTexture instance
%
%   [vt_, val] = getGLSLValue(vt_, name)
%
%   getGLSLValue will call the relevant GLSL function, supplied by
%   Psychtoolbox, to get the value of the GLSL variable with the given
%   name.  This is how you can access the parameters of a virtualTexture.
%
%   vt_ is an instance of dXvirtualTexture.  It is returned to reflect
%   changes made by this method.
%
%   name is a string with the name of a GLSL variable.  The name must match
%   exactly the name of a variable defined in the GLSL program to which
%   this dXvirtualTexture is attached.

% copyright 2008 Benjamin Heasly at the University of Pennsylvania

% reality check
global ROOT_STRUCT
if isempty(name) || ROOT_STRUCT.screenMode ~= 1
    return
    val_ = [];
end

% check to see if we already know the memory address of the named variable
if isempty(vt_.GLSLLocations) || ~isfield(name, vt_.GLSLLocations)

    % look for the named variable
    try
        loc = glGetUniformLocation(vt_.GLSLProgram, name);

        if loc < 0
            warning(sprintf('dXtexture/setGLSLValue: could not locate the variable %s in the GLSL program %d', name, vt_.GLSLProgram));
            val_ = [];
            return
        end

    catch
        warning(sprintf('dXtexture/setGLSLValue: either %d is an invalid GLSL program, or you need to open an onscreen Screen window', vt_.GLSLProgram));
        val_ = [];
        return
    end

    % found a location.  Store it by name
    vt_.GLSLLocations.(name) = loc;
end

% get the value by location and name
%   in a sec I'll come back and support more than just doubles
glUseProgram(vt_.GLSLProgram);
val_ = glGetUniformfv(vt_.GLSLProgram, vt_.GLSLLocations.(name));
glUseProgram(0);