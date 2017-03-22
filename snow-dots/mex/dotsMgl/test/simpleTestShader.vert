#version 120
// simple vertex shader used to test uniform get/set and transform feedback

// uniforms to get and set--scalars only, all treated as floats
uniform float fScalar;
uniform bool bScalar;
uniform vec4 fVec4;
uniform bvec4 bVec4;
uniform mat2 fMat2;
uniform mat4 fMat4;
uniform mat4x2 fMat4x2;
uniform mat2x3 fMat2x3;

// scalar value to overwrite x and y position
//  transform feedback should see the change in gl_Position.xy
uniform float xyOverwrite;

// arbitrary per-vertex data, input and output
//  transform feedback should see passthrough of data
attribute vec4 inputAttribute;
varying vec4 outputVarying;

void main() {

    // make sure the declared uniforms are counted as "active"
    fScalar;
    bScalar;
    fVec4;
    bVec4;
    fMat2;
    fMat4;
    fMat4x2;
    fMat2x3;

    // overwrite output x and y positions from the input uniform
    gl_Position	= gl_Vertex;
    gl_Position.xy = vec2(xyOverwrite, xyOverwrite);

    // let attribute data pass through
    outputVarying = inputAttribute;
}
