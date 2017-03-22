/*Get the value of a shader program uniform variable.
 *
 * value = dotsMglGetProgramVariable(variableInfo)
 *
 * variableInfo is a struct containing information about a shader program
 * uniform variable, as returned from dostMglLocateProgramVariable().
 *
 * Returns value, the current value of the shader uniform variable.  Value
 * is always returned as a Matlab double matrix.
 *
 * value may be a scalar or matrix with up to 4 rows or columns.  If the
 * uniform variable is a GLSL float, vec2, vec3, or vec4, value will have
 * 1 row.  If the variable is a GLSL "mat", value will have the
 * corresponding number of rows and columns.  For example, if the variable
 * is a mat4x3, value will have 4 columns and 3 rows.
 *
 * Note that Matlab and OpenGL both use the column-major matrix ordering.
 *
 * Although GLSL supports arrays of float, vec, and mat variables,
 * dotsMglGetProgramVariable() does not.
 *
 * 17 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    GLuint programID = 0;
    GLint location = 0;
    size_t elementRows = 0;
    size_t elementCols = 0;
    size_t elementSize = 0;
    
    GLfloat* uniformData = NULL;
    double* mxData = NULL;
    int dataIndex = 0;
    
    int status = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs != 1 || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        usageError("dotsMglGetProgramVariable");
        return;
    }
    
    // get basic variable info
    programID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "programID", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    location = (GLint)dotsMglGetInfoScalar(prhs[0], 0, "location", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    elementRows = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "elementRows", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    elementCols = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "elementCols", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // any data to get?
    elementSize = elementRows*elementCols;
    if (elementSize <= 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // allocate enough GLfloats to hold the uniform data
    uniformData = mxCalloc(elementSize, sizeof(GLfloat));
    if (uniformData == NULL) {
        mexPrintf("(dotsMglGetProgramVariable) Could not allocate GLfloat buffer with %d elements.\n",
                elementSize);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // copy the uniform data from the shader
    glGetUniformfv(programID, location, uniformData);
    error = glGetError();
    if(error != GL_NO_ERROR) {
        error = glGetError();
        mexPrintf("(dotsMglGetProgramVariable) Could not read variable data.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        
        if (uniformData != NULL) {
            mxFree(uniformData);
            uniformData = NULL;
        }
        return;
    }
    
    // create a return matrix for the uniform data
    plhs[0] = mxCreateDoubleMatrix(elementRows, elementCols, mxREAL);
    mxData = mxGetPr(plhs[0]);
    if(plhs[0] == NULL || mxData == NULL) {
        mexPrintf("(dotsMglGetProgramVariable) Could not create return matrix.\n");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        
        if (uniformData != NULL) {
            mxFree(uniformData);
            uniformData = NULL;
        }
        return;
    }
    
    // cast the uniform data elements into the output matrix
    //  GLSL and Matlab both use column-major matrices
    for (dataIndex=0; dataIndex < elementSize; dataIndex++)
        mxData[dataIndex] = (double)uniformData[dataIndex];
    
    // release buffered uniform data
    if (uniformData != NULL) {
        mxFree(uniformData);
        uniformData = NULL;
    }
}
