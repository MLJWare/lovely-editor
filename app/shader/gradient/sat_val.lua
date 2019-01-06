return love.graphics.newShader(require"shader.util.hsv2rgb" ..[[

extern float hue;

vec4 effect(vec4 _, Image texture, vec2 tex_pos, vec2 screen_pos) {
  vec3 color = hsv2rgb(hue, 1.0, 1.0);
  vec3 result = mix(vec3(0.0), mix(vec3(1.0), color, tex_pos.x), 1.0 - tex_pos.y);
  return vec4(result, 1.0);
}
]])
