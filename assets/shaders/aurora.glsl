// aurora.glsl — Aurora borealis / polar light effect
#version 460 core
precision highp float;
uniform float u_time;
uniform vec2  u_resolution;
out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    // TODO: Implement aurora curtain effect using sin/cos bands
    fragColor = vec4(0.2, 0.8, 0.4, 1.0);
}
