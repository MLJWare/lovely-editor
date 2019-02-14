local PropertyStore           = require "PropertyStore"
local CircleAction            = require "action.paint.Circle"
local unpack_color            = require "util.color.unpack"

return {
  id = "tool.circle";
  draw_hint = function (self, _, data, scale) -- might need to swap `_` and `data`
    if data ~= self._owner then return end
    local cx, cy = self._cx, self._cy
    local  x,  y = self._hint_x, self._hint_y
    local radius = ((x - cx)^2 + (y - cy)^2)^0.5
    love.graphics.setLineWidth(1)
    local color = PropertyStore.get("core.graphics", "paint.color")
    love.graphics.setColor(unpack_color(color))
    love.graphics.circle("line", cx*scale, cy*scale, radius*scale)
  end;
  on_press   = function (self, _, data, x, y)
    self._cx = x
    self._cy = y
    self._hint_x = x
    self._hint_y = y
    self._owner = data
  end;
  on_drag   = function (self, _, data, x, y)
    if data ~= self._owner then return end
    self._hint_x = x
    self._hint_y = y
  end;
  on_release = function (self, undoStack, data, x, y)
    if data ~= self._owner then return end
    local cx, cy = self._cx, self._cy
    local radius = ((x - cx)^2 + (y - cy)^2)^0.5
    local color = PropertyStore.get("core.graphics", "paint.color")
    undoStack:commit(CircleAction.apply(data, cx, cy, radius, color))
    self._owner = nil
  end;
};
