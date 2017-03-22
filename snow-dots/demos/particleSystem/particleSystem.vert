#version 120
// vertex shader for a particle system with a "gravity" attractor.

// uniforms are constant or change once per shape (in this case per frame)
//  they're inputs
uniform vec2 attractorPosition;
uniform float attractorRadius;
uniform float attractorG;
uniform float deltaT;

// attributes are specific to each vertex (in this case each particle)
//  they're inputs
attribute vec2 positionIn;
attribute vec2 velocityIn;

// varyings are specific to each vertex (in this case each particle)
//  they're outputs
varying vec2 positionOut;
varying vec2 velocityOut;

void main() {
    
    vec2 deltaP = attractorPosition - positionIn;
    float rSquared = deltaP.x*deltaP.x + deltaP.y*deltaP.y;
    
    if (attractorRadius*attractorRadius < rSquared) {
        float theta = atan(deltaP.y, deltaP.x);
        vec2 acceleration = vec2(cos(theta), sin(theta))*attractorG/rSquared;
        positionOut = positionIn
                + deltaT*velocityIn
                + 0.5*deltaT*deltaT*acceleration;
        velocityOut = velocityIn + deltaT*acceleration;
    } else {
        positionOut = positionIn;
        velocityOut = velocityIn;
    }
    
    gl_Position = gl_ModelViewProjectionMatrix * vec4(positionOut.xy, 0, 1);
    
    // set default color
    gl_FrontColor = vec4(1.0, 1.0, 1.0, 1.0);
}
