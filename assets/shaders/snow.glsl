// snow.glsl — Snowflake particle simulation
#version 460 core
precision highp float;
uniform float u_time;
uniform vec2  u_resolution;
out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    // TODO: Implement snowflake simulation with wind drift
    fragColor = vec4(1.0, 1.0, 1.0, 0.8);
}
