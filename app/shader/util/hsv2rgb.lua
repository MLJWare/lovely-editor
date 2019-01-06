return [[
#ifdef GL_ES
precision mediump float;
#endif

vec3 hsv2rgb(float h, float s, float v) {
  vec3 rgb = clamp(abs(mod(h + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
  rgb = rgb*rgb*(3.0 - 2.0*rgb);
  return v * mix(vec3(1.0), rgb, s);
}
]]
