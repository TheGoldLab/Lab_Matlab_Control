/*Find metadata about GLSL shader program variables.
 *
 * variableInfo = dotsMglLocateProgramVariable(programInfo, ...
 *  [uniformName])
 *
 * programInfo is a struct containing the OpenGL identifier and other
 * information about a shader program, as returned from
 * dotsMglCreateShaderProgram().
 *
 * uniformName is an optional string specifying the name of a shader
 * program uniform variable.  If uniformName matches the name of a uniform
 * variable used by the given shader program, returns a struct of metadata
 * for that uniform variable.
 *
 * If uniformName is omitted, returns a struct array of metadata about all
 * of the uniform variables used by the shader program.
 *
 * 17 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    GLuint programID = 0;
    GLint nUniforms = 0;
    GLuint uniformIndex = 0;
    GLsizei nameMaxLength = 0;
    GLsizei nameLength = 0;
    GLint arraySize = 0;
    size_t elementRows = 0;
    size_t elementCols = 0;
    GLenum uniformType = 0;
    GLchar *uniformName = NULL;
    GLint uniformLocation = -1;
    
    char* inName = NULL;
    int nOut = 0;
    size_t outIndex = 0;
    
    int status = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs < 1 || nrhs > 2 || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        usageError("dotsMglLocateProgramVariable");
        return;
    }
    
    // get the programID
    programID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "programID", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // how many active uniforms?
    glGetProgramiv(programID, GL_ACTIVE_UNIFORMS, &nUniforms);
    if(nUniforms <= 0) {
        error = glGetError();
        mexPrintf("(dotsMglLocateProgramVariable) Could not locate any variables.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // looking for one variable, or all?
    if (nrhs >= 2 && mxIsChar(prhs[1])) {
        inName = mxArrayToString(prhs[1]);
        nOut = 1;
    } else {
        inName = NULL;
        nOut = nUniforms;
    }
    
    // allocate buffer big enough for each uniform name
    glGetProgramiv(programID, GL_ACTIVE_UNIFORM_MAX_LENGTH, &nameMaxLength);
    uniformName = mxCalloc(nameMaxLength, sizeof(GLchar));
    
    // iterate active uniforms
    //  output all or one
    plhs[0] = mxCreateStructMatrix(1, nOut, NUM_UNIFORM_INFO_NAMES, UNIFORM_INFO_NAMES);
    for (uniformIndex = 0; uniformIndex < nUniforms; uniformIndex++) {
        
        // query for uniform information
        glGetActiveUniform(programID,
                uniformIndex,
                nameMaxLength,
                &nameLength,
                &arraySize,
                &uniformType,
                uniformName);
        dotsMglGetUniformDimensions(uniformType, &elementRows, &elementCols);
        if (nameLength > 0 && uniformName != NULL) {
            uniformLocation = glGetUniformLocation(programID, uniformName);
        } else {
            uniformLocation = -1;
            continue;
        }
        
        // ouput information for one or all uniforms
        if (inName == NULL || strcmp(inName, uniformName) == 0) {
            outIndex = (inName == NULL) ? uniformIndex : 0;
            mxSetField(plhs[0], outIndex, "programID", mxCreateDoubleScalar((double)programID));
            mxSetField(plhs[0], outIndex, "name", mxCreateString(uniformName));
            mxSetField(plhs[0], outIndex, "type", mxCreateDoubleScalar((double)uniformType));
            mxSetField(plhs[0], outIndex, "arraySize", mxCreateDoubleScalar((double)arraySize));
            mxSetField(plhs[0], outIndex, "elementRows", mxCreateDoubleScalar((double)elementRows));
            mxSetField(plhs[0], outIndex, "elementCols", mxCreateDoubleScalar((double)elementCols));
            mxSetField(plhs[0], outIndex, "index", mxCreateDoubleScalar((double)uniformIndex));
            mxSetField(plhs[0], outIndex, "location", mxCreateDoubleScalar((double)uniformLocation));
            
            if (inName != NULL)
                break;
        }
    }
    
    // release both name buffers
    if (uniformName != NULL) {
        mxFree(uniformName);
        uniformName = NULL;
    }
    if (inName != NULL) {
        mxFree(inName);
        inName = NULL;
    }
}