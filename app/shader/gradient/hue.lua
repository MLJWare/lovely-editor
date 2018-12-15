return love.graphics.newShader(require"shader.util.hsv2rgb" ..[[

vec4 effect(vec4 _, Image texture, vec2 tex_pos, vec2 screen_pos) {
  vec3 color = hsv2rgb((1-tex_pos.y)*6, 1.0, 1.0);
  return vec4(color, 1.0);
}
]])