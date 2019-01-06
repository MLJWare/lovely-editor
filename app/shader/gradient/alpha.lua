return love.graphics.newShader(require"shader.util.hsv2rgb" ..[[

extern float hue;
extern float sat;
extern float val;

vec4 effect(vec4 _, Image texture, vec2 tex_pos, vec2 screen_pos) {
  return vec4(hsv2rgb(hue, sat, val), 1.0 - tex_pos.y);
}]])
