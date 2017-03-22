/*Select ahead of time VBOs to use as generic vertex attributes.
 * 
 * nSelected = dotsMglSelectVertexAttributes(programInfo, bufferInfo, attribNames, ...
 *  [elementOffsets, isNormalized])
 *
 * programInfo is a struct containing the OpenGL identifier and other 
 * informaiton about a shader program, as returned from 
 * dotsMglCreateShaderProgram().
 *
 * bufferInfo is a struct array in which each element containins the OpenGL
 * identifier and other information about a VBO, as returned
 * from dotsMglCreateVertexBufferObject.  Each VBO should contain an array
 * of generic vertex attribute data.  bufferInfo fields such as 
 * elementsPerVertex and elementStride are used to locate attribute data 
 * for each vertex within the VBO.
 *
 * attribNames is a cell array of strings with a name for each of the VBOs.
 * Each name must match the name of a vertex attribute variable in the 
 * given shader program.
 * 
 * attribNames must be supplied at least once, before drawing.  When 
 * attribNames is supplied, the given shader program will be re-linked.
 * attribNames may be omitted in subsequent calls, in order to supply new
 * bufferInfo without re-linking the program.
 *
 * The elementOffsets argument is an optional double array containing an
 * offset into each VBO, to use as the starting location for reading vertex
 * data.  The default offset for each VBO is 0--the first element.
 *
 * The isNormalized argument is an optional double array specifying
 * whether to normalize integer data for each VBO.  Where
 * isNormalizedBuffer is non-zero, the VBO data be normalized.  Where
 * isNormalizedBuffer is zero, or if isNormalizedBuffer is omitted, VBO
 * data will not be normalized.
 *
 * If the programInfo or bufferInfo argument is missing or empty, all
 * generic vertex attributes numbered 1 and above will be disabled.
 *
 * Note that generic vertex attribute 0 corresponds to vertex position and
 * the "gl_Vertex" shader variable.  dotsMglSelectVertexAttributes
 * ignores attribute 0.
 *
 * Returns nSelected, the number of VBOs that were successfully selected.
 *
 * 24 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // input arguments
    GLuint programID = 0;
    size_t nBuffers = 0;
    size_t nNames = 0;
    size_t nOffsets = 0;
    size_t nIsNormalized = 0;
    
    // input data
    int i = 0;
    GLuint attribIndex = 1;
    mxArray* mxAttribName = NULL;
    char* attribName = NULL;
    double* mxOffsetData = NULL;
    double* mxIsNormalizedData = NULL;
    
    // VBO data
    GLuint bufferID = 0;
    size_t bytesPerElement = 0;
    size_t byteOffset = 0;
    GLint elementsPerVertex = 0;
    GLsizei elementStride = 0;
    GLsizei byteStride = 0;
    mxArray* mxData = NULL;
    GLenum glType = GL_FLOAT;
    GLboolean isNormalized = GL_FALSE;
    
    // status
    GLint maxAttributes = -1;
    size_t nSelected = 0;
    int status = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // empty input means disable all generic vertex attributes, exept 0
    if (nrhs < 1 || mxIsEmpty(prhs[0])) {
        glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &maxAttributes);
        if (maxAttributes > 0) {
            for (i=1; i<maxAttributes; i++)
                glDisableVertexAttribArray(i);
        }
        plhs[0] = mxCreateDoubleScalar(0);
        return;
    }
    
    // check input arguments
    if (nrhs < 2 || nrhs > 5
            || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])
            || !mxIsStruct(prhs[1]) || mxIsEmpty(prhs[1])) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglSelectVertexAttributes");
        return;
    }
    
    // is this a shader program info struct?
    programID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "programID", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    // how many attribute buffers?
    nBuffers = mxGetNumberOfElements(prhs[1]);
    
    // how many attribute names?
    if (nrhs >= 3 && mxIsCell(prhs[2]) && !mxIsEmpty(prhs[2])) {
        nNames = mxGetNumberOfElements(prhs[2]);
        if (nBuffers != nNames) {
            mexPrintf("(dotsMglSelectVertexAttributes) Number of buffer names %d must match number of buffers %d.\n",
                    nNames, nBuffers);
            plhs[0] = mxCreateDoubleScalar(-3);
            return;
        }
    }
    
    // how many buffer offsets?
    if (nrhs >= 4 && mxIsDouble(prhs[3]) && !mxIsEmpty(prhs[3])) {
        nOffsets = mxGetNumberOfElements(prhs[3]);
        if (nBuffers != nOffsets) {
            mexPrintf("(dotsMglSelectVertexAttributes) Number of buffer offsets %d must match number of buffers %d.\n",
                    nOffsets, nBuffers);
            plhs[0] = mxCreateDoubleScalar(-4);
            return;
        }
        mxOffsetData = mxGetPr(prhs[3]);
    }
    
    // how many buffer normalize flags?
    if (nrhs >= 5 && mxIsDouble(prhs[4]) && !mxIsEmpty(prhs[4])) {
        nIsNormalized = mxGetNumberOfElements(prhs[4]);
        if (nBuffers != nIsNormalized) {
            mexPrintf("(dotsMglSelectVertexAttributes) Number of buffer normalize flags %d must match number of buffers %d.\n",
                    nIsNormalized, nBuffers);
            plhs[0] = mxCreateDoubleScalar(-5);
            return;
        }
        mxIsNormalizedData = mxGetPr(prhs[4]);
    }
    
    // iterate buffers to enable attributes
    for (i=0; i<nBuffers; i++) {
        
        // enable the next numbered attribute
        //  ignoring attribute 0
        attribIndex = i+1;
        glEnableVertexAttribArray(attribIndex);
        
        // assign a name to the numbered attribute?
        if (nNames > 0){
            mxAttribName = mxGetCell(prhs[2], i);
            attribName = mxArrayToString(mxAttribName);
            
            glBindAttribLocation(programID, attribIndex, (const GLchar*)attribName);
            if (attribName != NULL){
                mxFree(attribName);
                attribName = NULL;
            }
            
            error = glGetError();
            if(error != GL_NO_ERROR) {
                mexPrintf("(dotsMglSelectVertexAttributes) Error assigning name %s to vertex attribute %d.  glGetError()=%d\n",
                        attribName, attribIndex, error);
                continue;
            }
        }
        
        // VBO accounting
        bufferID = (GLuint)dotsMglGetInfoScalar(prhs[1], i, "bufferID", &status);
        if (status < 0) {
            mexPrintf("(dotsMglSelectVertexAttributes) %dth buffer info struct is invalid.\n",
                    i);
            continue;
        }
        
        // how are the VBO elements formatted?
        elementsPerVertex = (GLint)dotsMglGetInfoScalar(prhs[1], i, "elementsPerVertex", &status);
        elementStride = (GLsizei)dotsMglGetInfoScalar(prhs[1], i, "elementStride", &status);
        bytesPerElement = (size_t)dotsMglGetInfoScalar(prhs[1], i, "bytesPerElement", &status);
        byteStride = elementStride * bytesPerElement;
        mxData = mxGetField(prhs[1], i, "mxData");
        glType = dotsMglGetGLNumericType(mxData);
        
        // use an offset into the VBO?
        if (nOffsets > 0 && mxOffsetData != NULL)
            byteOffset = (size_t)mxOffsetData[i] * bytesPerElement;
        else
            byteOffset = 0;
        
        // normalize data in the VBO?
        if (nIsNormalized > 0 && mxIsNormalizedData != NULL)
            isNormalized = mxIsNormalizedData[i] ? GL_TRUE : GL_FALSE;
        else
            isNormalized = 0;
        
        // assign the VBO to this numbered attribute
        glBindBuffer(GL_ARRAY_BUFFER, bufferID);
        glVertexAttribPointer(attribIndex,
                elementsPerVertex,
                glType,
                isNormalized,
                byteStride,
                BUFFER_OFFSET(byteOffset));
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        error = glGetError();
        if(error != GL_NO_ERROR) {
            mexPrintf("(dotsMglSelectVertexAttributes) Error selecting vertex %s data.  glGetError()=%d\n",
                    attribName, error);
            continue;
        }
        
        // success for this attribute
        nSelected++;
    }
    
    // need to re-link the program when binding attribute names
    if (nNames > 0){
        glLinkProgram(programID);
        error = glGetError();
        if (error != GL_NO_ERROR) {
            mexPrintf("(dotsMglSelectVertexAttributes) Could not link program.  glGetError()=%d\n",
                    error);
            plhs[0] = mxCreateDoubleScalar(-10);
            return;
        }
    }
    
    // success?
    plhs[0] = mxCreateDoubleScalar(nSelected);
}