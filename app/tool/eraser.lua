local painter                 = require "painter"
local FullReplaceAction       = require "action.paint.FullReplace"

local eraser_color = 0x00000000
return {
  id = "tool.eraser";
  on_press = function (self, _, data, x, y)
    self._old = data:clone()
    painter.pixel(data, x, y, eraser_color)
  end;
  on_drag = function (_, _, data, x, y, x2, y2)
    painter.line(data, x, y, x2, y2, eraser_color)
  end;
  on_release = function (self, undoStack, data)
    undoStack:commit(FullReplaceAction.apply(data, self._old))
  end;
};
