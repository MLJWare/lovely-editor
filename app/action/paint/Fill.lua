local painter                 = require "painter"

local Action = {}
Action.__index = Action

function Action:undo(data)
  data:paste(self._data, 0, 0)
end

function Action:redo(data)
  painter.fill(data, self._x, self._y, self._color)
end

function Action.apply(data, x, y, hex_color)
  local old_data = data:clone()
  painter.fill(data, x, y, hex_color)
  return setmetatable({
      _x     = x;
      _y     = y;
      _color = hex_color;
      _data  = old_data;
    }, Action)
end

return Action