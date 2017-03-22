/*Select ahead of time which VBO data to use when drawing vertices.
 *
 * nSelected = dotsMglSelectVertexData(bufferInfo, dataNames, ...
 *  [elementOffsets, isClientData])
 *
 * bufferInfo is a struct array in which each element containins the OpenGL
 * identifier and other information about a VBO, as returned
 * from dotsMglCreateVertexBufferObject.  Each VBO should contain an array
 * of vertex data.  bufferInfo fields such as elementsPerVertex and 
 * elementStride are used to locate data for each vertex within the VBO.
 *
 * dataNames is a cell array of strings.  Each element of dataNames
 * indicates the type of vertex data for the corresponding element of
 * bufferInfo.  Each element must be one of the following:
 *
 *  'vertex' - data to pass to glVertexPointer()
 *  'color' - data to pass to glColorPointer()
 *  'secondaryColor' - data to pass to glSecondaryColorPointer()
 *  'texCoord' - data to pass to glTexCoordPointer()
 *  'normal' - data to pass to glNormalPointer()
 *  'fogCoord' - data to pass to glFogCoordPointer()
 *
 * Other strings will be ignored.
 *
 * The elementOffsets argument is an optional double array containing an
 * offset into each VBO, to use as the starting location for reading vertex
 * data.  The default offset for each VBO is 0--the first element.
 *
 * isClientData is an optional flag which might help debugging.  If
 * isClientData is non-zero, vertex data are passed from Matlab application
 * memory instead of from OpenGL VBO memory.  isClientData should usually
 * be omitted.
 *
 * If the bufferInfo argument is missing or empty, all vertex data
 * selection is disabled.
 *
 * Returns nSelected, the number of VBOs that were successfully selected.
 *
 * 23 Sep 2011 created
 */

#include "dotsMgl.h"

// literals for choosing gl___Pointer functions
#define VERTEX_DATA_NAME "vertex"
#define COLOR_DATA_NAME "color"
#define SECONDARY_COLOR_DATA_NAME "secondaryColor"
#define TEX_COORD_DATA_NAME "texCoord"
#define NORMAL_DATA_NAME "normal"
#define FOG_COORD_DATA_NAME "fogCoord"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // input arguments
    size_t nBuffers = 0;
    size_t nNames = 0;
    size_t nOffsets = 0;
    
    // input data
    int i = 0;
    mxArray* mxDataName = NULL;
    char* dataName = NULL;
    double* mxOffsetData = NULL;
    
    // VBO data
    GLuint bufferID = 0;
    GLint elementsPerVertex = 0;
    size_t bytesPerElement = 0;
    GLsizei elementStride = 0;
    GLsizei byteStride = 0;
    size_t byteOffset = 0;
    mxArray* mxData = NULL;
    GLenum glType = GL_FLOAT;
    
    // status
    size_t nSelected = 0;
    int status = 0;
    
    dotsMglClearGLErrors();
    
    // empty input means disable all data selections
    if (nrhs < 1 || mxIsEmpty(prhs[0])) {
        glDisableClientState(GL_VERTEX_ARRAY);
        glDisableClientState(GL_COLOR_ARRAY);
        glDisableClientState(GL_SECONDARY_COLOR_ARRAY);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisableClientState(GL_NORMAL_ARRAY);
        glDisableClientState(GL_FOG_COORD_ARRAY);
        
        plhs[0] = mxCreateDoubleScalar(0);
        return;
    }
    
    // check input arguments
    if (nrhs < 2 || nrhs > 4
            || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])
            || !mxIsCell(prhs[1]) || mxIsEmpty(prhs[1])) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglSelectVertexData");
        return;
    }
    
    // how many data buffers?
    nBuffers = mxGetNumberOfElements(prhs[0]);
    
    // how many data names?
    nNames = mxGetNumberOfElements(prhs[1]);
    if (nBuffers != nNames) {
        mexPrintf("(dotsMglSelectVertexData) Number of buffer names %d must match number of buffers %d.\n",
                nNames, nBuffers);
        plhs[0] = mxCreateDoubleScalar(-2);
        return;
    }
    
    // how many buffer offsets?
    if (nrhs >= 3 && mxIsDouble(prhs[2]) && !mxIsEmpty(prhs[2])) {
        nOffsets = mxGetNumberOfElements(prhs[2]);
        if (nBuffers != nOffsets) {
            mexPrintf("(dotsMglSelectVertexData) Number of buffer offsets %d must match number of buffers %d.\n",
                    nOffsets, nBuffers);
            plhs[0] = mxCreateDoubleScalar(-4);
            return;
        }
        mxOffsetData = mxGetPr(prhs[2]);
    }
    
    // iterate buffers to enable data types
    for (i=0; i<nBuffers; i++) {
        
        // VBO accounting
        bufferID = (GLuint)dotsMglGetInfoScalar(prhs[0], i, "bufferID", &status);
        if (status < 0) {
            mexPrintf("(dotsMglSelectVertexAttributes) %dth buffer info struct is invalid.\n",
                    i);
            continue;
        }
        
        // how are the VBO elements formatted?
        elementsPerVertex = (GLint)dotsMglGetInfoScalar(prhs[0], i, "elementsPerVertex", &status);
        elementStride = (GLsizei)dotsMglGetInfoScalar(prhs[0], i, "elementStride", &status);
        bytesPerElement = (size_t)dotsMglGetInfoScalar(prhs[0], i, "bytesPerElement", &status);
        byteStride = elementStride * bytesPerElement;
        mxData = mxGetField(prhs[0], i, "mxData");
        glType = dotsMglGetGLNumericType(mxData);
        
        // use an offset into the VBO?
        if (nOffsets > 0 && mxOffsetData != NULL)
            byteOffset = (size_t)mxOffsetData[i] * bytesPerElement;
        else
            byteOffset = 0;
        
        // dig out the dataName string
        mxDataName = mxGetCell(prhs[1], i);
        dataName = mxArrayToString(mxDataName);
        
        // invoke the OpenGL "Pointer" function that matches dataName
        //  for debugging, try using a client data pointer
        if (nrhs >= 4
                && mxIsNumeric(prhs[3])
                && !mxIsEmpty(prhs[3])
                && mxGetScalar(prhs[3])) {
            
            void* mxClientPtr = mxGetData(mxData);
            
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            status = dotsMglVertexDataPointer(dataName,
                    elementsPerVertex,
                    glType,
                    byteStride,
                    mxClientPtr + byteOffset);
            
        } else {
            
            glBindBuffer(GL_ARRAY_BUFFER, bufferID);
            status = dotsMglVertexDataPointer(dataName,
                    elementsPerVertex,
                    glType,
                    byteStride,
                    BUFFER_OFFSET(byteOffset));
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
        
        if (dataName != NULL){
            mxFree(dataName);
            dataName = NULL;
        }
        
        // success for this data type?
        if (status >= 0)
            nSelected++;
    }
    
// success?
    plhs[0] = mxCreateDoubleScalar(nSelected);
}

// the GL vertex "Pointer" functions have similar but different forms
int dotsMglVertexDataPointer(char* dataName,
        GLint size,
        GLenum type,
        GLsizei stride,
        const GLvoid* pointer) {
    
    GLenum error = GL_NO_ERROR;
    
    //mexPrintf("%s size=%d type=%d stride=%d\n", 
    //        dataName, size, type, stride);
    
    // choose the named "Pointer" function
    if (strcmp(dataName, VERTEX_DATA_NAME)==0) {
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(size, type, stride, pointer);
        
    } else if (strcmp(dataName, COLOR_DATA_NAME)==0) {
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(size, type, stride, pointer);
        
    } else if (strcmp(dataName, SECONDARY_COLOR_DATA_NAME)==0) {
        glEnableClientState(GL_SECONDARY_COLOR_ARRAY);
        glSecondaryColorPointer(size, type, stride, pointer);
        
    } else if (strcmp(dataName, TEX_COORD_DATA_NAME)==0) {
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(size, type, stride, pointer);
        
    } else if (strcmp(dataName, NORMAL_DATA_NAME)==0) {
        glEnableClientState(GL_NORMAL_ARRAY);
        glNormalPointer(type, stride, pointer);
        
    } else if (strcmp(dataName, FOG_COORD_DATA_NAME)==0) {
        glEnableClientState(GL_FOG_COORD_ARRAY);
        glFogCoordPointer(type, stride, pointer);
        
    } else {
        mexPrintf("(dotsMglSelectVertexData) <%s> is not a valid data name.\n",
                dataName);
        return(-2);
    }
    
    error = glGetError();
    if(error != GL_NO_ERROR) {
        mexPrintf("(dotsMglSelectVertexData) Error selecting vertex <%s> data.  glGetError()=%d\n",
                dataName, error);
        return(-3);
    }
    
    // success!
    return(0);
}