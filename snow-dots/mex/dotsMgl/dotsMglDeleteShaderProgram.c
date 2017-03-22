/* Free resources and delete a GLSL shader program.
 *
 * dotsMglDeleteShaderProgram(programInfo)
 *
 * programInfo is a struct containing the OpenGL identifier and other
 * information about a shader program, as returned from
 * dotsMglCreateShaderProgram().
 *
 * 14 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int status;
    GLuint programID, vertexID, fragmentID;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs != 1 || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])) {
        usageError("dotsMglDeleteShaderProgram");
        return;
    }
    
    // get basic info about the program
    programID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "programID", &status);
    if (status < 0)
        programID = 0;
    
    vertexID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "vertexID", &status);
    if (status < 0)
        vertexID = 0;
    
    fragmentID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "fragmentID", &status);
    if (status < 0)
        fragmentID = 0;
    
    // free the program, shaders, and ids
    glDeleteShader(vertexID);
    glDeleteShader(fragmentID);
    glDeleteProgram(programID);
}
