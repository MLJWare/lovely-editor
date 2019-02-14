local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"
local paint_iter              = require "paint_iter"

local Action = {}
Action.__index = Action

function Action:undo(buffer)
  local pixels = self._pixels
  for i, x, y in paint_iter.rectangle(self._x1, self._y1, self._x2, self._y2, buffer:getDimensions()) do
    buffer:setPixel(x, y, unpack_color(pixels[i]))
  end
end

function Action:redo(buffer)
  local r, g, b, a = unpack_color(self._color)
  for _, x, y in paint_iter.rectangle(self._x1, self._y1, self._x2, self._y2, buffer:getDimensions()) do
    buffer:setPixel(x, y, r, g, b, a)
  end
end

--[[
format: {
  line_nr
  , removed_count, ...removed_strings...
  , inserted_count, ...inserted_strings...
}

-- example: newline at end of line 3 (creates new line 4)
{4, 0, 1, ""}

-- example: newline between "foo" and "baz" in line 2 "foobaz"
{2, 1, "foobaz", 2, "foo", "baz"}

-- example: replace "ello" with "i" in line 3 "Hello, World"
{3, 1, "Hello, World", 1, "Hi, World"}
--]]

function Action.apply(buffer, line, remove_count, ...)
  for i = 0, remove_count do



  return setmetatable({line, remove_count, ...}, Action)
end

return Action
