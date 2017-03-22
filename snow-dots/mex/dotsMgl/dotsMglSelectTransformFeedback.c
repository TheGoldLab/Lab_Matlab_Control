/*Select ahead of time which values to capture during transform feedback.
 *
 * nSelected = dotsMglSelectTransformFeedback(programInfo, bufferInfo, varyingNames, ...
 *  [elementOffsets])
 *
 * programInfo is a struct containing the OpenGL identifier and other
 * informaiton about a shader program, as returned from
 * dotsMglCreateShaderProgram().
 *
 * bufferInfo is a struct array in which each element containins the OpenGL
 * identifier and other information about a VBO, as returned
 * from dotsMglCreateVertexBufferObject.  Each VBO will receive vertex data
 * during transform feedback.
 *
 * varyingNames is a cell array of strings with a name for each VBO.
 * Each name must match the name of a varying variable in the given shader
 * program.
 *
 * varyingNames must be supplied at least once, before transform feedback.
 * When varyingNames is supplied, the given shader program will be
 * re-linked.  varyingNames may be omitted in subsequent calls, in order to
 * supply new bufferInfo without re-linking the program.
 *
 * The elementOffsets argument is an optional double array containing an
 * offset into each VBO, to use as the starting location for writing
 * feedback data.  The default offset for each VBO is 0--the first element.
 * bufferInfo fields such as elementsPerVertex are used to compute correct
 * byte offsets into each VBO.
 *
 * Note that selecting transform feedback requires insider knowledge about
 * the names and sizes of the shader program's varying variables.
 *
 * Transform feedback is not supported in all OpenGL 2.0 contexts.  This 
 * function relies on the GL_EXT_transform_feedback extension and returns 
 * immediately if the extension is not found.
 *
 * 21 Sep 2011 implemented
 */

#include "dotsMgl.h"
#define EXTENSION "GL_EXT_transform_feedback"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // input arguments
    GLuint programID = 0;
    size_t nBuffers = 0;
    size_t nNames = 0;
    size_t nOffsets = 0;
    
    // input data
    int i = 0;
    mxArray* mxVaryingName = NULL;
    GLchar** varyingNames = NULL;
    double* mxOffsetData = NULL;
    
    // VBO accounting
    GLuint bufferID = 0;
    size_t bytesPerElement = 0;
    size_t byteOffset = 0;
    GLenum bufferMode = GL_INTERLEAVED_ATTRIBS_EXT;
    
    // status
    size_t nSelected = 0;
    int status = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check for transform feedback extension!
    if (!dotsMglIsExtensionSupported(EXTENSION)){
        plhs[0] = mxCreateDoubleScalar(-1);
        mexPrintf("(dotsMglSelectTransformFeedback) %s is not supported!\n",
                EXTENSION);
        return;
    }
    
    // check input arguments
    if (nrhs < 1 || nrhs > 4
            || !mxIsStruct(prhs[0]) || mxIsEmpty(prhs[0])) {
        plhs[0] = mxCreateDoubleScalar(-2);
        usageError("dotsMglSelectTransformFeedback");
        return;
    }
    
    // get the programID
    programID = (GLuint)dotsMglGetInfoScalar(prhs[0], 0, "programID", &status);
    if (status < 0) {
        plhs[0] = mxCreateDoubleScalar(-3);
        return;
    }
    
    // how many feedback buffers?
    if (nrhs >= 2 && mxIsStruct(prhs[1]) && !mxIsEmpty(prhs[1]))
        nBuffers = mxGetNumberOfElements(prhs[1]);
    
    // no buffers means deselect all transform feedback varyings
    if (nBuffers == 0) {
        glTransformFeedbackVaryingsEXT(programID, 0, NULL, bufferMode);
        plhs[0] = mxCreateDoubleScalar(0);
        return;
    }
    
    // multiple buffers means deal each varying into a separate VBO
    if (nBuffers == 1)
        bufferMode = GL_INTERLEAVED_ATTRIBS_EXT;
    else
        bufferMode = GL_SEPARATE_ATTRIBS_EXT;
    
    // how many varying names?
    if (nrhs >= 3 && mxIsCell(prhs[2]) && !mxIsEmpty(prhs[2])) {
        nNames = mxGetNumberOfElements(prhs[2]);
        if (nBuffers != nNames) {
            mexPrintf("(dotsMglSelectTransformFeedback) Number of buffer names %d must match number of buffers %d.\n",
                    nNames, nBuffers);
            plhs[0] = mxCreateDoubleScalar(-4);
            return;
        }
    }
    
    // allocate array of c-string varying names
    if (nNames > 0) {
        varyingNames = mxCalloc(nNames, sizeof(GLchar*));
        if (varyingNames == NULL) {
            plhs[0] = mxCreateDoubleScalar(-5);
            mexPrintf("(dotsMglSelectTransformFeedback) Could not allocate buffer for %d varying names.\n",
                    nNames);
            return;
        }
    }
    
    // how many buffer offsets?
    if (nrhs >= 4 && mxIsDouble(prhs[3]) && !mxIsEmpty(prhs[3])) {
        nOffsets = mxGetNumberOfElements(prhs[3]);
        if (nBuffers != nOffsets) {
            mexPrintf("(dotsMglSelectTransformFeedback) Number of buffer offsets %d must match number of buffers %d.\n",
                    nOffsets, nBuffers);
            plhs[0] = mxCreateDoubleScalar(-6);
            return;
        }
        mxOffsetData = mxGetPr(prhs[3]);
    }
    
    // iterate buffers to bind to feedback locations
    //  and get varying names as c-strings
    for (i=0; i<nBuffers; i++) {
        
        // get the next varying name?
        if (nNames > 0 || varyingNames != NULL) {
            mxVaryingName = mxGetCell(prhs[2], i);
            if (mxIsChar(mxVaryingName) && !mxIsEmpty(mxVaryingName)){
                varyingNames[i] = (GLchar*)mxArrayToString(mxVaryingName);
            } else {
                varyingNames[i] = NULL;
            }
        }
        
        // VBO accounting
        bufferID = (GLuint)dotsMglGetInfoScalar(prhs[1], i, "bufferID", &status);
        if (status < 0) {
            mexPrintf("(dotsMglSelectTransformFeedback) %dth buffer info struct is invalid.\n",
                    i);
            continue;
        }
        
        // use an offset into the VBO?
        if (nOffsets > 0 && mxOffsetData != NULL) {
            bytesPerElement = (size_t)dotsMglGetInfoScalar(prhs[1], i, "bytesPerElement", &status);
            byteOffset = (size_t)mxOffsetData[i] * bytesPerElement;
            
        } else {
            byteOffset = 0;
        }
        
        // bind this vbo to the next transform feedback attachment point
        glBindBufferOffsetEXT(GL_TRANSFORM_FEEDBACK_BUFFER_EXT,
                i,
                bufferID,
                byteOffset);
        
        error = glGetError();
        if (error != GL_NO_ERROR) {
            plhs[0] = mxCreateDoubleScalar(-7);
            mexPrintf("(dotsMglBeginTransformFeedback) Could not bind buffer %d of %d (bufferID=%d) for transform feedback.  glGetError()=%d\n",
                    i, nBuffers, bufferID, error);
            continue;
        }
        
        // success for this buffer
        nSelected++;
    }
    
    // select new names of varying program variables
    if (nNames > 0 || varyingNames != NULL) {
        
        // tell OpenGL which varyings to capture for feedback
        glTransformFeedbackVaryingsEXT(programID,
                nNames,
                (const GLchar**)varyingNames,
                bufferMode);
        
        // done with c-string varying names
        for (i=0; i<nNames; i++) {
            if (varyingNames[i] != NULL) {
                mxFree(varyingNames[i]);
                varyingNames[i] = NULL;
            }
        }
        mxFree(varyingNames);
        varyingNames = NULL;
        
        error = glGetError();
        if (error != GL_NO_ERROR) {
            plhs[0] = mxCreateDoubleScalar(-8);
            mexPrintf("(dotsMglSelectTransformFeedback) Could not select %d varyings for transform feedback.  glGetError()=%d\n",
                    nNames, error);
            return;
        }
        
        // re-link the program to reflect new varying names
        glLinkProgram(programID);
        error = glGetError();
        if (error != GL_NO_ERROR) {
            mexPrintf("(dotsMglSelectTransformFeedback) Could not link program.  glGetError()=%d\n",
                    error);
            plhs[0] = mxCreateDoubleScalar(-9);
            return;
        }
    }
    
    // success!
    plhs[0] = mxCreateDoubleScalar(nSelected);
}
