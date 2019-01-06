local painter                 = require "painter"
local FullReplaceAction       = require "action.paint.FullReplace"
local PropertyStore           = require "PropertyStore"

return {
    id = "tool.pencil";
    on_press = function (self, _, data, x, y)
      self._old = data:clone()
      painter.pixel(data, x, y, PropertyStore.get("core.graphics", "paint.color"):hex())
    end;
    on_drag = function (_, _, data, x, y, x2, y2)
      painter.line(data, x, y, x2, y2, PropertyStore.get("core.graphics", "paint.color"):hex())
    end;
    on_release = function (self, undoStack, data)
      undoStack:commit(FullReplaceAction.apply(data, self._old))
    end;
  };
