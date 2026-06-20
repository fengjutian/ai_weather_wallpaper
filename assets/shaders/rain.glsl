// rain.glsl — Rain droplet particle simulation
#version 460 core
precision highp float;
uniform float u_time;
uniform vec2  u_resolution;
out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    // TODO: Implement rain particle simulation
    fragColor = vec4(0.2, 0.3, 0.6, 1.0);
}
