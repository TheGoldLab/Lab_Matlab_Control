/*Stop capturing transform feedback data.
 *
 * status = dotsMglEndTransformFeedback()
 *
 * Discontinues transform feedback and restores rasterization for the
 * OpenGL pipeline.
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
    
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check for transform feedback extension!
    if (!dotsMglIsExtensionSupported(EXTENSION)){
        plhs[0] = mxCreateDoubleScalar(-1);
        mexPrintf("(dotsMglBeginTransformFeedback) %s is not supported!\n",
                EXTENSION);
        return;
    }
    
    // check input arguments
    if (nrhs != 0) {
        plhs[0] = mxCreateDoubleScalar(-2);
        usageError("dotsMglEndTransformFeedback");
        return;
    }
    
    // stop capturing vertex or geometry shader output
    //  and restore the GL pipeline to do rasterizing
    //  (i.e. stuff gets displayed again)
    glEndTransformFeedbackEXT();
    glDisable(GL_RASTERIZER_DISCARD_EXT);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        mexPrintf("(dotsMglEndTransformFeedback) Error stopping transform feedback. glGetError()=%d\n",
                error);
        plhs[0] = mxCreateDoubleScalar(-3);
        return;
    }
    
    // OK!
    plhs[0] = mxCreateDoubleScalar(0);
}

