local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"
local paint_iter              = require "app.paint_iter"

local function paint_pixel(data, x, y, color)
  if x < 0 or y < 0 or x >= data:getWidth() or y >= data:getHeight() then return end
  local old_pixel = pack_color(data:getPixel(x, y))
  local r, g, b, a = unpack_color(color)
  data:setPixel(x, y, r, g, b, a)
  return old_pixel
end

local function paint_line(data, x1, y1, x2, y2, color)
  local r, g, b, a = unpack_color(color)
  for _, x, y in paint_iter.line(x1, y1, x2, y2, data:getDimensions()) do
    data:setPixel(x, y, r, g, b, a)
  end
end

local function paint_circle(data, cx, cy, radius, color)
  local r, g, b, a = unpack_color(color)
  for _, x, y in paint_iter.circle(cx, cy, radius, data:getDimensions()) do
    data:setPixel(x, y, r, g, b, a)
  end
end

local function paint_fill(data, px, py, color)
  local r, g, b, a = unpack_color(color)
  for _, x, y in paint_iter.fill(data, px, py, color, nil, data:getDimensions()) do
    data:setPixel(x, y, r, g, b, a)
  end
end

return {
  pixel  = paint_pixel;
  line   = paint_line;
  fill   = paint_fill;
  circle = paint_circle;
}