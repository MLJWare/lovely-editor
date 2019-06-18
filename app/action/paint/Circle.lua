local paint_iter              = require "paint_iter"
local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"

local Action = {}
Action.__index = Action

function Action:undo(data)
  local pixels = self._pixels
  for i, x, y in paint_iter.circle(self._cx, self._cy, self._radius, data:getDimensions()) do
    data:setPixel(x, y, unpack_color(pixels[i]))
  end
end

function Action:redo(data)
  local r, g, b, a = unpack_color(self._color)
  for _, x, y in paint_iter.circle(self._cx, self._cy, self._radius, data:getDimensions()) do
    data:setPixel(x, y, r, g, b, a)
  end
end

function Action.apply(data, cx, cy, radius, hex_color)
  local pixels = {}
  local r, g, b, a = unpack_color(hex_color)
  for i, x, y in paint_iter.circle(cx, cy, radius, data:getDimensions()) do
    pixels[i] = pack_color(data:getPixel(x, y))
    data:setPixel(x, y, r, g, b, a)
  end

  return setmetatable({
      _cx     = cx;
      _cy     = cy;
      _radius = radius;
      _color  = hex_color;
      _pixels = pixels;
    }, Action)
end

return Action
