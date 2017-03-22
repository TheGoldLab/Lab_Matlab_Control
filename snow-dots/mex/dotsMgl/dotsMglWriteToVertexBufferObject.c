/*Write data to an OpenGL vertex buffer object (VBO) or a sub-range.
 *
 * nElements = dotsMglWriteToVertexBufferObject(bufferInfo, data, ...
 *  [offsetElements, doReallocate])
 *
 * bufferInfo is a struct with contains the OpenGL identifier and other
 * information about a VBO, as returned from
 * dotsMglCreateVertexBufferObject().
 *
 * data is a numeric array containing data elements to write to the VBO.
 * The numeric type of data should match the numeric type of the VBO.
 *
 * offsetElements and nElements are optional, used to speciy a sub-range
 * within the VBO.  "Elements" are in units that agree with the  VBO's
 * numeric type, such as double, single, or int32.  One element may contain
 * multiple bytes.
 *
 * offsetElements specifies where to start writing data elements.  The
 * default is 0--the first element.
 *
 * doReallocate is an optional flag specifying whether or not to "orphan"
 * the VBO data store before writing.  Orphaning might improve performance
 * in some cases by allowing OpenGL to allocate a new data store for the
 * VBO intead of synchonizing access to the original data store.  The
 * default is 0, don't reallocate.
 *
 * On success, returns nElements, the number of elements written to the
 * VBO.  nElements should match numel(data).
 *
 * Note: dotsMglWriteToVertexBufferObject uses glMapBuffer() to write VBO
 * data.  glMapBufferRange() might privide better performance, but it's not
 * generally available to OpenGL 2.0 contexts.
 *
 * 2 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    GLuint bufferID = 0;
    GLenum usage = GL_STREAM_DRAW;
    GLenum target = GL_ARRAY_BUFFER;
    GLenum access = GL_WRITE_ONLY;
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
    int doReallocate = 0;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs < 2 || nrhs > 4
            || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])
            || !mxIsNumeric(prhs[1]) || mxIsEmpty(prhs[1])) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglWriteToVertexBufferObject");
        return;
    }
    
    // get basic info about VBO
    bufferID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "bufferID", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    target = (GLenum)dotsMglGetInfoScalar(prhs[0], 0, "target", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    usage = (GLenum)dotsMglGetInfoScalar(prhs[0], 0, "usage", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    nElements = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "nElements", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    nBytes = (size_t)dotsMglGetInfoScalar(prhs[0], 0, "nBytes", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    mxData = mxGetField(prhs[0], 0, "mxData");
    if (mxData == NULL) {
        mexPrintf("(dotsMglWriteToVertexBufferObject) Can not locate original data (needed as template).\n");
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    mxClass = mxGetClassID(mxData);
    
    // does this incoming data class match the original class?
    if (mxClass != mxGetClassID(prhs[1])){
        mexPrintf("(dotsMglWriteToVertexBufferObject) Class of given data (%d) does not match class of VBO data (%d).\n",
                mxGetClassID(prhs[1]), mxClass);
        plhs[0] = mxCreateDoubleScalar(-6);
        return;
    }
    
    // get basic info about input data
    nRangeElements = (size_t)mxGetNumberOfElements(prhs[1]);
    mxDataPtr = mxGetData(prhs[1]);
    
    // choose the range offset (expect 0-based offset)
    if (nrhs >= 3 && mxIsNumeric(prhs[2]) && !mxIsEmpty(prhs[2]))
        offsetElements = (size_t)mxGetScalar(prhs[2]);
    
    if ((offsetElements + nRangeElements) > nElements){
        mexPrintf("(dotsMglWriteToVertexBufferObject) Range offset=%d plus number of elements=%d exceeds VBO nElements-1=%d.\n",
                offsetElements, nRangeElements, nElements-1);
        plhs[0] = mxCreateDoubleScalar(-7);
        return;
    }
    
    // choose whether to reallocate the buffer storage
    if (nrhs >= 4 && mxIsNumeric(prhs[3]) && !mxIsEmpty(prhs[3]))
        doReallocate = (int)mxGetScalar(prhs[3]);
    
    // bind the buffer to its target, which makes it accessible
    glBindBuffer(target, bufferID);
    
    // may reallocate or "orphan" the VBO
    //  instead of waiting for safe access
    if (doReallocate > 0)
        glBufferData(target, nBytes, NULL, usage);
    
    // map the entire buffer for writing
    glDataPtr = glMapBuffer(target, access);
    if (glDataPtr == NULL) {
        error = glGetError();
        mexPrintf("(dotsMglWriteToVertexBufferObject) Could not map VBO for target=%d.  glGetError()=%d\n",
                target, error);
        plhs[0] = mxCreateDoubleScalar(-8);
        return;
    }
    
    // copy input data to VBO
    offsetBytes = offsetElements*mxGetElementSize(prhs[1]);
    nRangeBytes = nRangeElements*mxGetElementSize(prhs[1]);
    if ((offsetBytes + nRangeBytes) > nBytes){
        mexPrintf("(dotsMglWriteToVertexBufferObject) Range offset %d plus number of bytes %d exceeds VBO nBytes-1 %d.\n",
                offsetBytes, nRangeBytes, nBytes-1);
        plhs[0] = mxCreateDoubleScalar(-9);
        return;
    }
    memcpy(glDataPtr+offsetBytes, mxDataPtr, nRangeBytes);
    
    // unmap the entire buffer
    isMapSuccess = glUnmapBuffer(target);
    glBindBuffer(target, 0);
    if(isMapSuccess == GL_FALSE) {
        error = glGetError();
        mexPrintf("(dotsMglWriteToVertexBufferObject) Writing VBO for target=%d caused data corruption!  glGetError()=%d\n",
                target, error);
        mxDestroyArray(plhs[0]);
        plhs[0] = mxCreateDoubleScalar(-10);
        return;
    }
    plhs[0] = mxCreateDoubleScalar(nRangeElements);
}