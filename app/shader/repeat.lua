return love.graphics.newShader([[
  uniform Image image;
  uniform float scale;
  vec4 effect(vec4 color, Image _, vec2 tex_coords, vec2 screen_coords)
  {
    vec4 pixel = Texel(image, screen_coords/scale);
    return pixel*color;
  }
]])