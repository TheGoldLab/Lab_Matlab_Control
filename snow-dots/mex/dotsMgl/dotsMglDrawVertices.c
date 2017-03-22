/*Draw vertices from data and attributes selected ahead of time.
 *
 * nVertices = dotsMglDrawVertices(primitive, nVertices,
 *  [vertexOffset, size, eboInfo])
 *
 * Draw vertices from buffered data and attributes which were chosen ahead
 * of time with dotsMglSelectVertexData() or 
 * dotsMglSelectVertexAttributes().
 *
 * primitive is an index specifying which OpenGL drawing mode to use.
 * Valid primitives are:
 *
 *  0   GL_POINTS
 *  1   GL_LINE_STRIP
 *  2   GL_LINE_LOOP
 *  3   GL_LINES
 *  4   GL_TRIANGLE_STRIP
 *  5   GL_TRIANGLE_FAN
 *  6   GL_TRIANGLES
 *  7   GL_QUAD_STRIP
 *  8   GL_QUADS
 *  9   GL_POLYGON
 *
 * The default is 0.
 *
 * nVertices is the nubmer of vertices to draw.  The vertex data and
 * attributes which were selected ahead of time must contain at least this
 * many vertices.  Otherwise, Matlab might crash.
 *
 * vertexOffset is an optional offset into the data and attributes which
 * were selected ahead of time, specifying the first vertex to draw.  The
 * default offset is 0--the first vertex.
 *
 * size is an optional value specifying the size in pixels of points
 * (primitive = 0) or lines (primitive = 0, 1, 2, or 3).  Default is to 
 * leave point and line size unchanged.
 *
 * eboInfo is an optional struct containing the OpenGL identifier and
 * other information about a buffer object, as returned from
 * dotsMglCreateVertexBufferObject.  This buffer object is treated as an
 * "element buffer object".  It must contain unsigned integer data and each
 * integer is treated as the index of a vertex.  This allows drawing of
 * non-sequential vertices from among the data and attributes which were
 * selected ahead of time.
 *
 * If eboInfo is provided, nVertices and vertexOffset refer to vertex 
 * indices, instead of vertex data and attributes.
 *
 * Note: eboInfo allows dotsMglDrawVertices() to invoke glDrawElements()
 * instead of glDrawArrays().  This may allow OpenGL to optimize things
 * like vertex sharing and caching.
 *
 * Returns the number of vertices drawn, which should match the given
 * nVertices.
 *
 * 23 September 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // drawing parameters
    size_t primitiveIndex = 0;
    GLenum primitive = GL_POINTS;
    GLsizei nVertices = 0;
    GLint offsetVertices = 0;
    GLfloat size = 1;
    
    // VBO data for indexed drawing
    GLuint bufferID = 0;
    size_t bytesPerElement = 0;
    size_t byteOffset = 0;
    mxArray* mxData = NULL;
    GLenum glType = GL_UNSIGNED_INT;
    
    // status
    int status = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs < 2 || nrhs > 5
            || !mxIsNumeric(prhs[0]) || mxIsEmpty(prhs[0])
            || !mxIsNumeric(prhs[1]) || mxIsEmpty(prhs[1])) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglDrawVertices");
        return;
    }
    
    // choose the primitive drawing type
    primitiveIndex = (size_t)mxGetScalar(prhs[0]);
    if (primitiveIndex >= 0 && primitiveIndex < NUM_GL_PRIMITIVES) {
        primitive = GL_PRIMITIVES[primitiveIndex];
    } else {
        mexPrintf("(dotsMglDrawVertices) Primitive index %d is out of defined range %d - %d.\n",
                primitiveIndex, 0, NUM_GL_PRIMITIVES-1);
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    // choose how many vertices to draw
    //  client state should be enabled and disabled with
    //  dotsMglSelectVertexData and dotsMglSelectVertexAttributes
    nVertices = (GLsizei)mxGetScalar(prhs[1]);
    
    // choose the range offset, if supplied.  Expect 0-based offset
    if (nrhs >= 3 && mxIsNumeric(prhs[2]) && !mxIsEmpty(prhs[2]))
        offsetVertices = (size_t)mxGetScalar(prhs[2]);
    
    // choose the point or line size, if supplied
    if (nrhs >= 4 && mxIsNumeric(prhs[3]) && !mxIsEmpty(prhs[3])) {
        size = (GLfloat)mxGetScalar(prhs[3]);
        if (primitiveIndex == 0) {
            glPointSize(size);
            
        } else if (primitiveIndex <= 3) {
            glLineWidth(size);
        }
    }
    
    // draw vertices with previously chosen data
    glEnableClientState(GL_VERTEX_ARRAY);
    if (nrhs >= 5 && mxIsStruct(prhs[4]) && !mxIsEmpty(prhs[4])) {
        
        // draw specific elements of the enabled arrays
        // VBO accounting
        bufferID = (GLuint)dotsMglGetInfoScalar(prhs[4], 0, "bufferID", &status);
        if (status < 0) {
            mexPrintf("(dotsMglSelectVertexData) index buffer info struct is invalid.\n");
            plhs[0] = mxCreateDoubleScalar(-3);
            return;
        }
        bytesPerElement = (size_t)dotsMglGetInfoScalar(prhs[4], 0, "bytesPerElement", &status);
        byteOffset = offsetVertices * bytesPerElement;
        mxData = mxGetField(prhs[4], 0, "mxData");
        glType = dotsMglGetGLNumericType(mxData);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bufferID);
        glDrawElements(primitive, nVertices, glType, BUFFER_OFFSET(byteOffset));
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
    } else {
        
        // draw enabled arrays sequentially
        glDrawArrays(primitive, offsetVertices, nVertices);
    }
    
    error = glGetError();
    if(error != GL_NO_ERROR) {
        mexPrintf("(dotsMglDrawVertices) Error drawing vertices.  glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleScalar(-10);
        return;
    }
    
    // success!
    plhs[0] = mxCreateDoubleScalar(nVertices);
}