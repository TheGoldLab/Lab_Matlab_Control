/*Activate a GLSL shader program, replacing OpenGL fixed functionality.
 *
 * status = dotsMglUseShaderProgram(programInfo)
 *
 * programInfo is a struct containing the OpenGL identifier and other
 * information about a shader program, as returned from
 * dotsMglCreateShaderProgram().
 *
 * On success, reuturns a nonzero status number.
 *
 * 16 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int status;
    GLuint programID = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs > 1) {
        usageError("dotsMglUseShaderProgram");
        plhs[0] = mxCreateDoubleScalar(-1);
        return;
    }
    
    if (nrhs < 1 || mxIsEmpty(prhs[0])) {
        // empty input means revert to OpenGL fixed pipeline
        glUseProgram(0);
        
    } else if(mxIsStruct(prhs[0])) {
        // info struct describing OpenGL shader program
        programID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "programID", &status);
        if (status >= 0)
            glUseProgram(programID);
    }
    
    error = glGetError();
    if (error != GL_NO_ERROR) {
        mexPrintf("(dotsMglUseShaderProgram) Could not use program.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    // success!  programID >= 0
    plhs[0] = mxCreateDoubleScalar(programID);
}
