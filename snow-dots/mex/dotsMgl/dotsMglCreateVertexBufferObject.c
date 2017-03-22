/*Create an OpenGL vertex buffer object (VBO).
 *
 * bufferInfo = dotsMglCreateVertexBufferObject(data, ...
 *  [target, usage, elementsPerVertex, elementStride])
 *
 * data is a numeric array with data to put in a VBO.  The VBO will try to
 * accomodate the size and numeric type of data.
 *
 * target is an index to specify the default OpenGL binding target for the
 * VBO.  Valid targets are:
 *
 *  0   GL_ARRAY_BUFFER
 *  1   GL_ELEMENT_ARRAY_BUFFER
 *  2   GL_PIXEL_PACK_BUFFER
 *  3   GL_PIXEL_UNPACK_BUFFER
 *
 * The default is 0.
 *
 * usage is an index to specify an OpenGL usage hint, which may help
 * OpenGL do optimization.  Valid usages are:
 *
 *  0   GL_STREAM_DRAW
 *  1   GL_STREAM_READ
 *  2   GL_STREAM_COPY
 *  3   GL_STATIC_DRAW
 *  4   GL_STATIC_READ
 *  5   GL_STATIC_COPY
 *  6   GL_DYNAMIC_DRAW
 *  7   GL_DYNAMIC_READ
 *  8   GL_DYNAMIC_COPY
 *
 * The default is 0.
 *
 * elementsPerVertex specifies the data "size"--the number of numeric
 * components to use for each vertex.  For example, XYZ position or RGB
 * color data would have 3 elements per vertex.  The default is 1.
 *
 * elementStride specifies the number of elements between vertices.  For
 * example, an array with interleaved XYZRGB position and color data could
 * use a stride of 6 elements.  The default is 0, which assumes elements
 * are tightly packed.
 *
 * On success, returns a struct with contains the OpenGL identifier and
 * other information about the new VBO.
 *
 * 1 September 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    size_t targetIndex = 0;
    size_t usageIndex = 0;
    size_t nElements = 0;
    size_t nBytes = 0;
    size_t bytesPerElement = 0;
    mxArray* mxData = NULL;
    const GLvoid* data;
    GLuint bufferID = 0;
    GLenum target = GL_ARRAY_BUFFER;
    GLenum usage = GL_STREAM_DRAW;
    GLenum error = GL_NO_ERROR;
    GLint elementsPerVertex = 1;
    GLsizei elementStride = 0;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs < 1 || nrhs > 5 || !mxIsNumeric(prhs[0]) || mxIsEmpty(prhs[0])) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglCreateVertexBufferObject");
        return;
    }
    
    // get basic info about input data mxArray
    data = mxGetData(prhs[0]);
    nElements = mxGetNumberOfElements(prhs[0]);
    bytesPerElement = mxGetElementSize(prhs[0]);
    nBytes = nElements*bytesPerElement;
    
    // choose the VBO binding target
    if (nrhs >= 2 && mxIsNumeric(prhs[1]) && !mxIsEmpty(prhs[1])) {
        targetIndex = (size_t)mxGetScalar(prhs[1]);
        if (targetIndex >= 0 && targetIndex < NUM_GL_TARGETS)
            target = GL_TARGETS[targetIndex];
    }
    
    // choose the VBO usage type
    if (nrhs >= 3 && mxIsNumeric(prhs[2]) && !mxIsEmpty(prhs[2])) {
        usageIndex = (size_t)mxGetScalar(prhs[2]);
        if (usageIndex >= 0 && usageIndex < NUM_GL_USAGES)
            usage = GL_USAGES[usageIndex];
    }
    
    // choose number of elements per vertex (e.g. xy, xyz, rgba, etc).
    if (nrhs >= 4 && mxIsNumeric(prhs[3]) && !mxIsEmpty(prhs[3])) {
        elementsPerVertex = (GLint)mxGetScalar(prhs[3]);
    }
    
    // choose vertex stride, if any (e.g. xyrgbxyrgb)
    if (nrhs >= 5 && mxIsNumeric(prhs[4]) && !mxIsEmpty(prhs[4])) {
        elementStride = (GLsizei)mxGetScalar(prhs[4]);
    }
    
    // request a bufferID for the new VBO
    glGenBuffers(1, &bufferID);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        mexPrintf("(dotsMglCreateVertexBufferObject) Could not get bufferID for VBO.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleScalar((double)error);
        return;
    }
    
    // bind the new VBO to its first target
    glBindBuffer(target, bufferID);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        mexPrintf("(dotsMglCreateVertexBufferObject) Could not bind VBO to target %d.  glGetError()=%d\n",
                target, error);
        plhs[0] = mxCreateDoubleScalar((double)error);
        return;
    }
    
    // write the given data to the VBO
    glBufferData(target, nBytes, data, usage);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        mexPrintf("(dotsMglCreateVertexBufferObject) Could write VBO data.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleScalar((double)error);
        return;
    }
    
    // unbind the buffer until user uses it
    glBindBuffer(target, 0);
    
    // return a struct of info about the VBO
    plhs[0] = mxCreateStructMatrix(1, 1, NUM_VBO_INFO_NAMES, VBO_INFO_NAMES);
    mxSetField(plhs[0], 0, "bufferID", mxCreateDoubleScalar((double)bufferID));
    mxSetField(plhs[0], 0, "nElements", mxCreateDoubleScalar((double)nElements));
    mxSetField(plhs[0], 0, "elementsPerVertex", mxCreateDoubleScalar((double)elementsPerVertex));
    mxSetField(plhs[0], 0, "elementStride", mxCreateDoubleScalar((double)elementStride));
    mxSetField(plhs[0], 0, "elementStride", mxCreateDoubleScalar((double)elementStride));
    mxSetField(plhs[0], 0, "nBytes", mxCreateDoubleScalar((double)nBytes));
    mxSetField(plhs[0], 0, "bytesPerElement", mxCreateDoubleScalar((double)bytesPerElement));
    mxSetField(plhs[0], 0, "target", mxCreateDoubleScalar((double)target));
    mxSetField(plhs[0], 0, "targetIndex", mxCreateDoubleScalar((double)targetIndex));
    mxSetField(plhs[0], 0, "usage", mxCreateDoubleScalar((double)usage));
    mxSetField(plhs[0], 0, "usageIndex", mxCreateDoubleScalar((double)usageIndex));
    mxSetField(plhs[0], 0, "mxData", mxDuplicateArray(prhs[0]));
}