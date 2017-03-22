/* Support Snow Dots extensions to the mgl project.
 *
 * Snow Dots and mgl are both released under GNU Public Licenses.
 * See snow-dots/mex/dotsMgl/COPYING
 *
 * 2 September 2011 created
 * 14 September 2011 added shader program support
 */

#include "mgl.h"

// macro to access VBO data by offsets
//  from http://www.opengl.org/wiki/Vertex_Buffer_Object
//  scraped on 7 Sept 2011
#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// possible OpenGL buffer binding targets
const GLenum GL_TARGETS[] = {GL_ARRAY_BUFFER,
GL_ELEMENT_ARRAY_BUFFER,
GL_PIXEL_PACK_BUFFER,
GL_PIXEL_UNPACK_BUFFER};
const int NUM_GL_TARGETS = sizeof(GL_TARGETS) / sizeof(GL_TARGETS[0]);

// possible OpenGL buffer usage styles
const GLenum GL_USAGES[] = {GL_STREAM_DRAW,
GL_STREAM_READ,
GL_STREAM_COPY,
GL_STATIC_DRAW,
GL_STATIC_READ,
GL_STATIC_COPY,
GL_DYNAMIC_DRAW,
GL_DYNAMIC_READ,
GL_DYNAMIC_COPY};
const int NUM_GL_USAGES = sizeof(GL_USAGES) / sizeof(GL_USAGES[0]);

// possible OpenGL drawing primitives
const GLenum GL_PRIMITIVES[] = {GL_POINTS,
GL_LINE_STRIP,
GL_LINE_LOOP,
GL_LINES,
GL_TRIANGLE_STRIP,
GL_TRIANGLE_FAN,
GL_TRIANGLES,
GL_QUAD_STRIP,
GL_QUADS,
GL_POLYGON};
const int NUM_GL_PRIMITIVES = sizeof(GL_PRIMITIVES) / sizeof(GL_PRIMITIVES[0]);

// names of info fields about Vertex Buffer Objects
const char* VBO_INFO_NAMES[] = {"bufferID",
"nElements",
"elementsPerVertex",
"elementStride",
"nBytes",
"bytesPerElement",
"target",
"targetIndex",
"usage",
"usageIndex",
"mxData"};
const int NUM_VBO_INFO_NAMES = sizeof(VBO_INFO_NAMES) / sizeof(VBO_INFO_NAMES[0]);

// names of info fields about GLSL shader programs
const char* SHADER_INFO_NAMES[] = {"programID",
"programLog",
"vertexID",
"vertexSource",
"vertexLog",
"fragmentID",
"fragmentSource",
"fragmentLog"};
const int NUM_SHADER_INFO_NAMES = sizeof(SHADER_INFO_NAMES) / sizeof(SHADER_INFO_NAMES[0]);

// names of info fields about GLSL shader uniform variables
const char* UNIFORM_INFO_NAMES[] = {"programID",
"name",
"type",
"arraySize",
"elementRows",
"elementCols",
"index",
"location"};
const int NUM_UNIFORM_INFO_NAMES = sizeof(UNIFORM_INFO_NAMES) / sizeof(UNIFORM_INFO_NAMES[0]);

// get the value of one of an info struct field
double dotsMglGetInfoScalar(const mxArray *info, size_t index, const char *name, int *status) {
    mxArray *field;
    double scalar;
    
    if (info == NULL || index < 0 || name == NULL)
        field = NULL;
    else
        field = mxGetField(info, index, name);
    
    if (field == NULL) {
        mexPrintf("(dotsMgl) Could not find info named <%s>.\n", name);
        scalar = 0;
        if (status != NULL)
            *status = -1;
    } else {
        scalar = mxGetScalar(field);
        if (status != NULL)
            *status = 0;
    }
    return(scalar);
}

// clear out any pre-existing OpenGL errors
void dotsMglClearGLErrors() {
    GLenum error;
    error = glGetError();
    while (error != GL_NO_ERROR)
        error = glGetError();
}

// utility to detect OpenGL extensions
//  from http://www.opengl.org/resources/features/OGLextensions/
//  scraped on 2 Sept 2011
//  for example, isRanged = isExtensionSupported("ARB_map_buffer_range");
int dotsMglIsExtensionSupported(const char *extension) {
    const GLubyte *extensions = NULL;
    const GLubyte *start;
    GLubyte *where, *terminator;
    
    /* Extension names should not have spaces. */
    where = (GLubyte *) strchr(extension, ' ');
    if (where || *extension == '\0')
        return 0;
    extensions = glGetString(GL_EXTENSIONS);
    
    /* It takes a bit of care to be fool-proof about parsing the
     * OpenGL extensions string. Don't be fooled by sub-strings,
     * etc. */
    start = extensions;
    for (;;) {
        where = (GLubyte *) strstr((const char *) start, extension);
        if (!where)
            break;
        terminator = where + strlen(extension);
        if (where == start || *(where - 1) == ' ')
            if (*terminator == ' ' || *terminator == '\0')
                return 1;
        start = terminator;
    }
    return 0;
}

// utility to get size information for GLSL shader uniform variables
void dotsMglGetUniformDimensions(GLenum type, size_t* rows, size_t* cols){
    size_t uniformRows = 0;
    size_t uniformCols = 0;
    
    switch (type) {
        case GL_FLOAT:
            uniformRows = 1;
            uniformCols = 1;
            break;
        case GL_FLOAT_VEC2:
            uniformRows = 1;
            uniformCols = 2;
            break;
        case GL_FLOAT_VEC3:
            uniformRows = 1;
            uniformCols = 3;
            break;
        case GL_FLOAT_VEC4:
            uniformRows = 1;
            uniformCols = 4;
            break;
        case GL_INT:
            uniformRows = 1;
            uniformCols = 1;
            break;
        case GL_INT_VEC2:
            uniformRows = 1;
            uniformCols = 2;
            break;
        case GL_INT_VEC3:
            uniformRows = 1;
            uniformCols = 3;
            break;
        case GL_INT_VEC4:
            uniformRows = 1;
            uniformCols = 4;
            break;
        case GL_BOOL:
            uniformRows = 1;
            uniformCols = 1;
            break;
        case GL_BOOL_VEC2:
            uniformRows = 1;
            uniformCols = 2;
            break;
        case GL_BOOL_VEC3:
            uniformRows = 1;
            uniformCols = 3;
            break;
        case GL_BOOL_VEC4:
            uniformRows = 1;
            uniformCols = 4;
            break;
        case GL_FLOAT_MAT2:
            uniformRows = 2;
            uniformCols = 2;
            break;
        case GL_FLOAT_MAT3:
            uniformRows = 3;
            uniformCols = 3;
            break;
        case GL_FLOAT_MAT4:
            uniformRows = 4;
            uniformCols = 4;
            break;
        case GL_FLOAT_MAT2x3:
            uniformRows = 3;
            uniformCols = 2;
            break;
        case GL_FLOAT_MAT2x4:
            uniformRows = 4;
            uniformCols = 2;
            break;
        case GL_FLOAT_MAT3x2:
            uniformRows = 2;
            uniformCols = 3;
            break;
        case GL_FLOAT_MAT3x4:
            uniformRows = 4;
            uniformCols = 3;
            break;
        case GL_FLOAT_MAT4x2:
            uniformRows = 2;
            uniformCols = 4;
            break;
        case GL_FLOAT_MAT4x3:
            uniformRows = 3;
            uniformCols = 4;
            break;
    }
    
    if (rows != NULL)
        *rows = uniformRows;
    
    if (cols != NULL)
        *cols = uniformCols;
}

// utility to pick GL numeric types based on mxArray's classID
GLenum dotsMglGetGLNumericType(mxArray* mxData){
    GLenum glType = GL_FLOAT;
    mxClassID mxClass = mxUNKNOWN_CLASS;
    
    if (mxData != NULL && mxIsNumeric(mxData)) {
        
        mxClass = mxGetClassID(mxData);
        switch (mxClass) {
            case mxDOUBLE_CLASS:
                glType = GL_DOUBLE;
                break;
            case mxSINGLE_CLASS:
                glType = GL_FLOAT;
                break;
            case mxINT8_CLASS:
                glType = GL_BYTE;
                break;
            case mxINT16_CLASS:
                glType = GL_SHORT;
                break;
            case mxINT32_CLASS:
                glType = GL_INT;
                break;
            case mxUINT8_CLASS:
                glType = GL_UNSIGNED_BYTE;
                break;
            case mxUINT16_CLASS:
                glType = GL_UNSIGNED_SHORT;
                break;
            case mxUINT32_CLASS:
                glType = GL_UNSIGNED_INT;
                break;
        }
    }
    
    return(glType);
}