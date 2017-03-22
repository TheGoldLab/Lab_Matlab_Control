/*Read data from an OpenGL vertex buffer object (VBO) or a sub-range.
 *
 * data = dotsMglReadFromVertexBufferObject(bufferInfo, ...
 *  [offsetElements, nElements])
 *
 * bufferInfo is a struct with contains the OpenGL identifier and other
 * information about a VBO, as returned from
 * dotsMglCreateVertexBufferObject().
 *
 * offsetElements and nElements are optional, used to speciy a sub-range of
 * data within the VBO.  "Elements" are in units that agree with the  VBO's 
 * numeric type, such as double, single, or int32.  One element may contain
 * multiple bytes.
 * 
 * offsetElements specifies where to start reading data elements.  The 
 * default is 0--the first element.
 * 
 * nElements specifies the number of number of elements to read, starting 
 * at the offset.  The default is all of the elements from the offset to
 * the end of the VBO.
 *
 * On success, returns data, a numeric array which contains the elements of 
 * the VBO or the specified sub-range.
 *
 * Note: dotsMglReadFromVertexBufferObject uses glMapBuffer() to read VBO 
 * data.  glMapBufferRange() might privide better performance, but it's not
 * generally available to OpenGL 2.0 contexts.
 *
 * 2 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    GLuint bufferID = 0;
    GLenum target = GL_ARRAY_BUFFER;
    GLenum access = GL_READ_ONLY;
    GLenum error = GL_NO_ERROR;
    int status;
    void* glDataPtr = NULL;
    void* mxDataPtr = NULL;
    mxArray* mxData = NULL;
    mxClassID mxClass = mxDOUBLE_CLASS;
    size_t nElements = 0;
    size_t nBytes = 0;
    size_t offsetElements = 0;
    size_t nRangeElements = 0;
    size_t offsetBytes = 0;
    size_t nRangeBytes = 0;
    GLboolean isMapSuccess = GL_FALSE;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs < 1 || nrhs > 3 || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        usageError("dotsMglReadFromVertexBufferObject");
        return;
    }
    
    // get basic info about VBO
    bufferID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "bufferID", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    target = (GLenum)dotsMglGetInfoScalar(prhs[0], 0, "target", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    nElements = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "nElements", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    nBytes = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "nBytes", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    mxData = mxGetField(prhs[0], 0, "mxData");
    if (mxData == NULL) {
        mexPrintf("(dotsMglReadFromVertexBufferObject) Can not locate original data (needed as template).\n");
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    mxClass = mxGetClassID(mxData);
    
    // choose the range offset (expect 0-based offset)
    if (nrhs >= 2 && mxIsNumeric(prhs[1]) && !mxIsEmpty(prhs[1]))
        offsetElements = (size_t)mxGetScalar(prhs[1]);
    
    // choose the range number of elements
    if (nrhs >= 3 && mxIsNumeric(prhs[2]) && !mxIsEmpty(prhs[2]))
        nRangeElements = (size_t)mxGetScalar(prhs[2]);
    
    if (nRangeElements <= 0)
        nRangeElements = nElements - offsetElements;
    
    if ((offsetElements + nRangeElements) > nElements){
        mexPrintf("(dotsMglReadFromVertexBufferObject) Range offset=%d plus number of elements=%d exceeds VBO nElements-1=%d.\n",
                offsetElements, nRangeElements, nElements);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // create return matrix
    plhs[0] = mxCreateNumericMatrix(1, nRangeElements, mxClass, mxREAL);
    if (plhs[0] == NULL) {
        mexPrintf("(dotsMglReadFromVertexBufferObject) Could not create return matrix with %d elements.\n",
                nRangeElements);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // map the entire buffer for reading
    glBindBuffer(target, bufferID);
    glDataPtr = glMapBuffer(target, access);
    if (glDataPtr == NULL) {
        error = glGetError();
        mexPrintf("(dotsMglReadFromVertexBufferObject) Could not map VBO for target=%d.  glGetError()=%d\n",
                target, error);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    
    // copy data from VBO to return matrix
    offsetBytes = offsetElements*mxGetElementSize(plhs[0]);
    nRangeBytes = nRangeElements*mxGetElementSize(plhs[0]);
    if ((offsetBytes + nRangeBytes) > nBytes){
        mexPrintf("(dotsMglReadFromVertexBufferObject) Range offset %d plus number of bytes %d exceeds VBO nBytes-1 %d.\n",
                offsetBytes, nRangeBytes, nBytes-1);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
    mxDataPtr = mxGetData(plhs[0]);
    memcpy(mxDataPtr, glDataPtr+offsetBytes, nRangeBytes);
    
    // unmap the entire buffer
    isMapSuccess = glUnmapBuffer(target);
    glBindBuffer(target, 0);
    if(isMapSuccess == GL_FALSE) {
        error = glGetError();
        mexPrintf("(dotsMglReadFromVertexBufferObject) Reading VBO for target=%d caused data corruption!  glGetError()=%d\n",
                target, error);
        mxDestroyArray(plhs[0]);
        plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
        return;
    }
}