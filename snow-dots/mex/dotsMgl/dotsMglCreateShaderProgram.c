/*Create a GLSL shader program from source strings.
 *
 * programInfo = dotsMglCreateShaderProgram(vertexSource, fragmentSource)
 *
 * vertexSource and fragmentSource are strings (char arrays), each
 * containing source code for a GLSL vertex shader or fragment shader.
 * vertexSource, fragmentSource, or both may be supplied.
 *
 * Returns programInfo, which is a struct containing the OpenGL identifier
 * and other information about a new shader program.
 *
 * If there is a compilation error, programInfo will contain debugging
 * information in the vertexLog or fragmentLog field.  If there is a
 * linking error programInfo will contain debugging information in the
 * programLog field.
 *
 * Note: dotsMglCreateShaderProgram() does not accept source strings for
 * geometry shaders, which are not generally available in OpenGL 2.0
 * contexts.  Perhaps a second function could use extensions to attach a
 * geometry shader and re-link the program.
 *
 * 14 Sep 2011 created
 */

#include "dotsMgl.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    GLuint programID = 0;
    GLuint vertexID = 0;
    GLuint fragmentID = 0;
    mxArray* vertexSource = NULL;
    mxArray* fragmentSource = NULL;
    mxArray* programLog = NULL;
    mxArray* vertexLog = NULL;
    mxArray* fragmentLog = NULL;
    
    char* sourceString = NULL;
    char* logString = NULL;
    GLsizei logLength = 0;
    
    GLint success = 0;
    GLenum error = GL_NO_ERROR;
    
    dotsMglClearGLErrors();
    
    // check input arguments
    if (nrhs < 1 || nrhs > 2) {
        plhs[0] = mxCreateDoubleScalar(-1);
        usageError("dotsMglCreateShaderProgram");
        return;
    }
    
    // try to create and compile the vertex shader
    if (nrhs >= 1 && mxIsChar(prhs[0]) && !mxIsEmpty(prhs[0])) {
        vertexSource = mxDuplicateArray(prhs[0]);
        sourceString = mxArrayToString(vertexSource);
        
        success = dotsMglNewShaderFromSource(
                (const GLchar*)sourceString,
                GL_VERTEX_SHADER,
                &vertexID,
                &logLength,
                (GLchar**)&logString);
        
        if (sourceString != NULL) {
            mxFree(sourceString);
            sourceString = NULL;
        }
        
        // always try to return the log
        if (logLength > 0 && logString!=NULL) {
            vertexLog = mxCreateString(logString);
            mxFree(logString);
            logString = NULL;
            logLength = 0;
        }
        
        if (!success) {
            error = glGetError();
            mexPrintf("(dotsMglCreateShaderProgram) Could not create vertex shader.  glGetError()=%d\n",
                    error);
        }
    }
    
    // try to create and compile the fragment shader
    if (nrhs >= 2 && mxIsChar(prhs[1]) && !mxIsEmpty(prhs[1])) {
        fragmentSource = mxDuplicateArray(prhs[1]);
        sourceString = mxArrayToString(fragmentSource);
        
        success = dotsMglNewShaderFromSource(
                (const GLchar*)sourceString,
                GL_FRAGMENT_SHADER,
                &fragmentID,
                &logLength,
                (GLchar**)&logString);
        
        if (sourceString != NULL) {
            mxFree(sourceString);
            sourceString = NULL;
        }
        
        // always try to return the log
        if (logLength > 0 && logString!=NULL) {
            fragmentLog = mxCreateString(logString);
            mxFree(logString);
            logString = NULL;
            logLength = 0;
        }
        
        if (!success) {
            error = glGetError();
            mexPrintf("(dotsMglCreateShaderProgram) Could not create fragment shader.  glGetError()=%d\n",
                    error);
        }
    }
    
    // is there anything to do?
    if (vertexID == 0 && fragmentID == 0) {
        mexPrintf("(dotsMglCreateShaderProgram) No shaders to load, cannot create program.\n");
        
    } else {
        
        // link the shaders into a program
        programID = glCreateProgram();
        if (vertexID != 0)
            glAttachShader(programID, vertexID);
        if (fragmentID != 0)
            glAttachShader(programID, fragmentID);
        glLinkProgram(programID);
        glGetProgramiv(programID, GL_LINK_STATUS, &success);
        
        // always try to return the program log
        glValidateProgram(programID);
        glGetProgramiv(programID, GL_INFO_LOG_LENGTH, (GLint*)&logLength);
        if (logLength > 0) {
            logString = mxCalloc((size_t)logLength, sizeof(GLchar));
            if (logString != NULL) {
                glGetProgramInfoLog(programID, logLength*sizeof(GLchar),
                        &logLength, logString);
                
                if (logLength > 0 && logString!=NULL) {
                    programLog = mxCreateString(logString);
                    mxFree(logString);
                    logString = NULL;
                    logLength = 0;
                }
            }
        }
        
        // on failure, free the useless program
        if (!success) {
            glDeleteProgram(programID);
            error = glGetError();
            mexPrintf("(dotsMglCreateShaderProgram) Could not link program.  glGetError()=%d\n",
                    error);
        }
        
    }
    
    // return a struct of info about the program, even upon failure
    plhs[0] = mxCreateStructMatrix(1, 1, NUM_SHADER_INFO_NAMES, SHADER_INFO_NAMES);
    mxSetField(plhs[0], 0, "programID", mxCreateDoubleScalar((double)programID));
    mxSetField(plhs[0], 0, "programLog", programLog);
    mxSetField(plhs[0], 0, "vertexID", mxCreateDoubleScalar((double)vertexID));
    mxSetField(plhs[0], 0, "vertexSource", vertexSource);
    mxSetField(plhs[0], 0, "vertexLog", vertexLog);
    mxSetField(plhs[0], 0, "fragmentID", mxCreateDoubleScalar((double)fragmentID));
    mxSetField(plhs[0], 0, "fragmentSource", fragmentSource);
    mxSetField(plhs[0], 0, "fragmentLog", fragmentLog);
}

// Given GLSL shader source and type,
//  make a new shader and compile it.
//  return status, shader programID, and compilation log
//  caller must mxFree() the compilation log
GLint dotsMglNewShaderFromSource(const GLchar *source, GLenum type,
        GLuint* shaderID, GLsizei* logLenght, GLchar** compileLog) {
    
    GLint compileSuccess = GL_FALSE;
    
    if (source==NULL || shaderID==NULL)
        return(0);
    
    if (!(type==GL_VERTEX_SHADER || type==GL_FRAGMENT_SHADER))
        return(0);
    
    // make a new shader object and try to compule the given source
    *shaderID = glCreateShader(type);
    glShaderSource(*shaderID, 1, &source, NULL);
    glCompileShader(*shaderID);
    glGetShaderiv(*shaderID, GL_COMPILE_STATUS, &compileSuccess);
    
    // get the log regardless of success of failure
    if (logLenght!=NULL && compileLog!=NULL) {
        *logLenght = 0;
        *compileLog = NULL;
        
        // how long is the log?
        glGetShaderiv(*shaderID, GL_INFO_LOG_LENGTH, (GLint*)logLenght);
        
        if (*logLenght > 0) {
            // allocate for the log
            *compileLog = mxCalloc(*logLenght, sizeof(GLchar));
            
            if (*compileLog != NULL) {
                glGetShaderInfoLog(*shaderID, (*logLenght)*sizeof(GLchar),
                        logLenght,  *compileLog);
            }
        }
    }
    
    // on failure, free the useless shader
    if (!compileSuccess){
        glDeleteShader(*shaderID);
        *shaderID = 0;
    }
    
    return(compileSuccess);
}