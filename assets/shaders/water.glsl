// water.glsl — Water ripple / refraction effect
// Uniforms passed from the wallpaper engine:
//   u_time     — Elapsed time in seconds
//   u_resolution — Viewport resolution (width, height)
//   u_mouse   — Normalized mouse position (0.0–1.0)

#version 460 core

precision highp float;

uniform float u_time;
uniform vec2  u_resolution;
uniform vec2  u_mouse;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    // TODO: Implement water ripple simulation
    fragColor = vec4(uv.x, uv.y, 1.0, 1.0);
}
