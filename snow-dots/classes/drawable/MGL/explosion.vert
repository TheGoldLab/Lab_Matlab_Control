#version 120
// vertex shader for the dotsDrawableExplosion

// constant acceleration vector
uniform vec3 acceleration;

// time is the index for the system
uniform float currentTime;

// piecewise trajectories (1-4) per vertex
attribute float time1;
attribute float time2;
attribute float time3;
attribute float time4;
attribute vec3 position1;
attribute vec3 position2;
attribute vec3 position3;
attribute vec3 position4;
attribute vec3 velocity1;
attribute vec3 velocity2;
attribute vec3 velocity3;
attribute vec3 velocity4;

// resting time for each vertex
attribute float restTime;

void main() {
    
    // which of the 4 trajectories are we in?
    float deltaT;
    vec3 p;
    vec3 v;
    if (currentTime >= restTime) {
        // after rest time, hold "motion" constant
        deltaT = restTime - time4;
        p = position4;
        v = velocity4;
    } else if (currentTime >= time4) {
        deltaT = currentTime - time4;
        p = position4;
        v = velocity4;
    } else if (currentTime >= time3) {
        deltaT = currentTime - time3;
        p = position3;
        v = velocity3;
    } else if (currentTime >= time2) {
        deltaT = currentTime - time2;
        p = position2;
        v = velocity2;
    } else {
        deltaT = currentTime - time1;
        p = position1;
        v = velocity1;
    }
    
    // calculate position within the current trajectory
    vec3 position = p + deltaT*v + 0.5*deltaT*deltaT*acceleration;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(position, 1);
    
    // let vertex color pass through
    gl_FrontColor = gl_Color;
    gl_BackColor = gl_Color;
}
