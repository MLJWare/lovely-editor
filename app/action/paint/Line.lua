local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"
local paint_iter              = require "paint_iter"

local Action = {}
Action.__index = Action

function Action:undo(data)
  local pixels = self._pixels
  for i, x, y in paint_iter.line(self._x1, self._y1, self._x2, self._y2, data:getDimensions()) do
    data:setPixel(x, y, unpack_color(pixels[i]))
  end
end

function Action:redo(data)
  local r, g, b, a = unpack_color(self._color)
  for _, x, y in paint_iter.line(self._x1, self._y1, self._x2, self._y2, data:getDimensions()) do
    data:setPixel(x, y, r, g, b, a)
  end
end

function Action.apply(data, x1, y1, x2, y2, hex_color)
  local pixels = {}
  local r, g, b, a = unpack_color(hex_color)
  for i, x, y in paint_iter.line(x1, y1, x2, y2, data:getDimensions()) do
    pixels[i] = pack_color(data:getPixel(x, y))
    data:setPixel(x, y, r, g, b, a)
  end

  return setmetatable({
      _x1     = x1;
      _y1     = y1;
      _x2     = x2;
      _y2     = y2;
      _color  = hex_color;
      _pixels = pixels;
    }, Action)
end

return Action
