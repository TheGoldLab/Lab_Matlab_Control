/*Delete an OpenGL vertex buffer object (VBO).
 *
 * dotsMglDeleteVertexBufferObject(bufferInfo)
 *
 * bufferInfo is a struct with contains the OpenGL identifier and other
 * information about a VBO, as returned from
 * dotsMglCreateVertexBufferObject().
 *
 * 1 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int status;
    GLuint bufferID;
    GLenum target;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs != 1 || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])) {
        usageError("dotsMglDeleteVertexBufferObject");
        return;
    }
    
    // get basic info about VBO
    bufferID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "bufferID", &status);
    if (status < 0)
        bufferID = 0;
    
    target = (GLenum)dotsMglGetInfoScalar(prhs[0], 0, "target", &status);
    if (status < 0)
        target = GL_ARRAY_BUFFER;
    
    // try to unbind the target, regardless of bufferID or data
    glBindBuffer(target, 0);
    
    // free the buffer and its bufferID
    glDeleteBuffers(1, &bufferID);
}
