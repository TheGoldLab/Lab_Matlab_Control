/*Start capturing transform feedback data from subsequent drawing.
 *
 * status = dotsMglBeginTransformFeedback(primitive, doDiscard)
 *
 * primitive is an index hinting at which OpenGL drawing mode will be used
 * during drawing.  This primitive must agree with the primitive passed to
 * dotsMglDrawVertices.  Valid primitives are:
 *
 *  0   GL_POINTS
 *  3   GL_LINES
 *  6   GL_TRIANGLES
 *
 * The default is 0.  The value 3 accomodates several "line" drawing modes
 * such as lines and line loops.  The value 6 accomodates several
 * "triangle" modes, such as triangles, triangle strips, quads, and quad
 * strips.
 *
 * doDiscard is an optional flag specifying whether or not to truncate the
 * OpenGL rendering pipeline.  If doDiscard is nonzero, rasterization is
 * discarded and nothing will show up on the screen.  The default is to
 * allow rasterization so that graphics will appear as usual.
 *
 * On success, returns a non-negative status number.
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
    
    int primitiveIndex = 0;
    GLenum primitive = GL_POINTS;
    int doRasterizerDiscard = 0;
    
    int status;
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
    if (nrhs < 1 || nrhs > 2 || !mxIsDouble(prhs[0]) || mxIsEmpty(prhs[0])) {
        plhs[0] = mxCreateDoubleScalar(-2);
        usageError("dotsMglBeginTransformFeedback");
        return;
    }
    
    // choose kind of primitive will be captured
    primitiveIndex = mxGetScalar(prhs[0]);
    if (primitiveIndex >= 0 && primitiveIndex < NUM_GL_PRIMITIVES)
        primitive = GL_PRIMITIVES[primitiveIndex];
    
    // choose to truncate the GL pipeline or allow drawing
    if (nrhs >= 2 && mxIsDouble(prhs[1]) && !mxIsEmpty(prhs[1])) {
        if (mxGetScalar(prhs[1]))
            glEnable(GL_RASTERIZER_DISCARD_EXT);
        else
            glDisable(GL_RASTERIZER_DISCARD_EXT);
    }
    
    // start capturing varyings
    glBeginTransformFeedbackEXT(primitive);
    error = glGetError();
    if (error != GL_NO_ERROR) {
        mexPrintf("(dotsMglSelectTransformFeedback) Could not begin transform feedback for primitive index %d (primitive=%d).  glGetError()=%d\n",
                primitiveIndex, primitive, error);
        plhs[0] = mxCreateDoubleScalar(-3);
        return;
    }
    
    // success!
    plhs[0] = mxCreateDoubleScalar(0);
}
