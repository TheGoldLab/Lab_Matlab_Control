/*Set the value of a shader program uniform variable.
 *
 * elementSize = dotsMglSetProgramVariable(variableInfo, value)
 *
 * variableInfo is a struct containing information about a shader program
 * uniform variable, as returned from dostMglLocateProgramVariable().
 *
 * value is a numeric value to assign to the program variable.  It must be
 * floating point, with Matlab class 'double' or 'single.  All values are
 * treated as OpenGL's 'GLfloat' type.
 *
 * value may be a scalar or matrix with up to 4 rows or columns.  If value
 * has 1 row, it is treated as a float, vec2, vec3, or vec4 GLSL variable.
 * If value has multiple rows, it is treated as a GLSL "mat" variable with
 * the corresponding number of rows and columns.  For example, if value has
 * 4 columns and 3 rows, it is treated as a mat4x3 variable.
 *
 * Note that Matlab and OpenGL both use the column-major matrix ordering.
 *
 * On success, a positive elementSize, which should match the number or
 * columns times the numbe of rows of value.
 *
 * Although GLSL supports arrays of float, vec, and mat variables, 
 * dotsMglSetProgramVariable() does not.
 *
 * 17 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    GLint location = 0;
    GLenum type = 0;
    size_t elementRows = 0;
    size_t elementCols = 0;
    size_t elementSize = 0;
    size_t mxCols = 0;
    size_t mxRows = 0;
    size_t mxSize = 0;
    
    GLfloat* uniformData = NULL;
    void* mxDataPtr = NULL;
    int dataIndex = 0;
    
    int status = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs != 2 || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])
    || !mxIsNumeric(prhs[1]) || mxIsEmpty(prhs[1])) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglSetProgramVariable");
        return;
    }
    
    // only accept floating point inputs
    if (!(mxIsDouble(prhs[1]) || mxIsSingle(prhs[1]))) {
        mexPrintf("(dotsMglSetProgramVariable) Given value muse be floating point (double or single class).\n");
        plhs[0] = mxCreateDoubleScalar(-1);
        return;
    }
    
    // get basic variable info
    location = (GLint)dotsMglGetInfoScalar(prhs[0], 0, "location", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    type = (GLint)dotsMglGetInfoScalar(prhs[0], 0, "type", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    elementRows = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "elementRows", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    elementCols = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "elementCols", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    // do data sizes match?
    elementSize = elementRows*elementCols;
    mxCols = mxGetN(prhs[1]);
    mxRows = mxGetM(prhs[1]);
    mxSize = mxCols * mxRows;
    if (elementRows != mxRows || elementCols != mxCols) {
        mexPrintf("(dotsMglSetProgramVariable) size of given value [%d %d] does not match size of program variable [%d %d].\n",
                mxRows, mxCols, elementRows, elementCols);
        plhs[0] = mxCreateDoubleScalar(-3);
        return;
        
    }
    
    // allocate enough GLfloats to hold the uniform data
    uniformData = mxCalloc(elementSize, sizeof(GLfloat));
    if (uniformData == NULL) {
        mexPrintf("(dotsMglSetProgramVariable) Could not allocate GLfloat buffer with %d elements.\n",
                elementSize);
        plhs[0] = mxCreateDoubleScalar(-4);
        return;
    }
    
    // cast the input matrix elements into the uniform data
    //  GLSL and Matlab both use column-major matrices
    mxDataPtr = mxGetData(prhs[1]);
    if (mxIsDouble(prhs[1])) {
        for (dataIndex=0; dataIndex < elementSize; dataIndex++)
            uniformData[dataIndex] = (GLfloat)((double*)mxDataPtr)[dataIndex];
        
    } else if (mxIsFloat(prhs[1])) {
        for (dataIndex=0; dataIndex < elementSize; dataIndex++)
            uniformData[dataIndex] = (GLfloat)((float*)mxDataPtr)[dataIndex];
    }
    
    
    // copy the uniform data to the shader
    if (elementRows == 1) {
        // scalar and vector uniforms have 1 row
        switch (elementCols) {
            case 1:
                glUniform1fv(location, 1, uniformData);
                break;
            case 2:
                glUniform2fv(location, 1, uniformData);
                break;
            case 3:
                glUniform3fv(location, 1, uniformData);
                break;
            case 4:
                glUniform4fv(location, 1, uniformData);
                break;
        }
        
    } else {
        // matrix uniforms have multiple rows
        //  GL_FALSE -- no need to transpose matrices
        switch (type) {
            case GL_FLOAT_MAT2:
                glUniformMatrix2fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT3:
                glUniformMatrix3fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT4:
                glUniformMatrix4fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT2x3:
                glUniformMatrix2x3fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT2x4:
                glUniformMatrix2x4fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT3x2:
                glUniformMatrix3x2fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT3x4:
                glUniformMatrix3x4fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT4x2:
                glUniformMatrix4x2fv(location, 1, GL_FALSE, uniformData);
                break;
            case GL_FLOAT_MAT4x3:
                glUniformMatrix4x3fv(location, 1, GL_FALSE, uniformData);
                break;
        }
    }
    
    error = glGetError();
    if(error != GL_NO_ERROR) {
        mexPrintf("(dotsMglSetProgramVariable) Could not write variable data.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleScalar(-5);
    } else {
        plhs[0] = mxCreateDoubleScalar(elementSize);
    }
    
    // release buffered uniform data
    if (uniformData != NULL) {
        mxFree(uniformData);
        uniformData = NULL;
    }
}
