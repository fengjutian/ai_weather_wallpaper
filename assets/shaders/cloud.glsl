// cloud.glsl — Cloud layer scrolling effect
#version 460 core
precision highp float;
uniform float u_time;
uniform vec2  u_resolution;
out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    // TODO: Implement layered cloud scrolling using FBM noise
    fragColor = vec4(0.9, 0.9, 1.0, 1.0);
}
