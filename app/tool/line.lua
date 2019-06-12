local PropertyStore           = require "PropertyStore"
local LineAction              = require "action.paint.Line"
local unpack_color            = require "util.color.unpack"
return {
    id = "tool.line";
    draw_hint = function (self, data, _, _, scale)
      if data ~= self._owner then return end
      local x1, y1 = self._x1, self._y1
      local x2, y2 = self._x2, self._y2
      love.graphics.setLineWidth(1)
    local color = PropertyStore.get("core.graphics", "paint.color")
    love.graphics.setColor(unpack_color(color))
      love.graphics.line(x1*scale, y1*scale, x2*scale, y2*scale)
    end;
    on_press   = function (self, _, data, x, y)
      self._x1 = x
      self._y1 = y
      self._x2 = x
      self._y2 = y
      self._owner = data
    end;
    on_drag   = function (self, _, data, x, y)
      if data ~= self._owner then return end
      self._x2 = x
      self._y2 = y
    end;
    on_release = function (self, undoStack, data, x2, y2)
      if data ~= self._owner then return end
      local x1, y1 = self._x1, self._y1
      local color = PropertyStore.get("core.graphics", "paint.color")
      undoStack:commit(LineAction.apply(data, x1, y1, x2, y2, color))
      self._owner = nil
    end;
  }
