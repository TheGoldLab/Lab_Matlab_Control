/*Wait for OpenGL to finish processing all commands.
 *
 * dotsMglFinish()
 *
 * Exposes glFinish() behavior to Matlab.  glFinish() causes the calling
 * application (Matlab) to block until OpenGL is finished processing all
 * previous commands, such as drawing and rendering.
 *
 * dotsMglFinish() is useful for timing measurements.  Unlike mglFlush(),
 * dotsMglFinish() doesn't cause a frame buffer swap.
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs!=0) {
        usageError("dotsMglFinish");
        return;
    }
    
    glFinish();
}
