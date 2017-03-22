/*Toggle OpenGL switches related to "smoothness" of graphics.
 *
 * dotsMglSmoothness(whichSwitch, isOn)
 *
 * whichSwitch is a string specifying which kind of smoothness to toggle.
 * whichSwitch may be one of the following:
 *
 *  'points' - alpha blending and and "nicest" points available
 *  'lines' - alpha blending and and "nicest" lines available
 *  'polygons' - alpha blending and and "nicest" polygons available
 *  'textures' - linear interpolation for 1D, 2D, and rectangular textures
 *  'scene' - alpha blending and full scene antialiasing by multisampling
 *
 * isOn is a flag specifying whether smoothness should be turned on or off.
 *
 * The exact meaning of smoothness depends on the OpenGL software and
 * hardware being used.  In some casess, toggling a smoothness switch may
 * have no effect.
 *
 * 19 Aug 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    char* whichSwitch = NULL;
    int isOn = 0;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs != 2 || !mxIsChar(prhs[0]) || !mxIsNumeric(prhs[1])) {
        usageError("dotsMglSmoothness");
        return;
    }
    whichSwitch = mxArrayToString(prhs[0]);
    isOn = mxGetScalar(prhs[1]) != 0;
    //mexPrintf("switching %s to %d\n", whichSwitch, isOn);
    
    // toggle the specified smoothness switch
    if (!strcmp(whichSwitch, "points")) {
        
        if (isOn) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_POINT_SMOOTH);
            glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
            
        } else {
            glDisable(GL_BLEND);
            glDisable(GL_POINT_SMOOTH);
        }
        
    } else if (!strcmp(whichSwitch, "lines")) {
        
        if (isOn) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_LINE_SMOOTH);
            glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
            
        } else {
            glDisable(GL_BLEND);
            glDisable(GL_LINE_SMOOTH);
        }
        
    } else if (!strcmp(whichSwitch, "polygons")) {
        
        if (isOn) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_POLYGON_SMOOTH);
            glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
            
        } else {
            glDisable(GL_BLEND);
            glDisable(GL_POLYGON_SMOOTH);
        }
        
    } else if (!strcmp(whichSwitch, "textures")) {
        
        if (isOn) {
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            
        } else {
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }
        
    } else if (!strcmp(whichSwitch, "scene")) {
        
        if (isOn) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_MULTISAMPLE);
            
        } else {
            glDisable(GL_BLEND);
            glDisable(GL_MULTISAMPLE);
        }
        
    } else {
        usageError("dotsMglSmoothness");
    }
}