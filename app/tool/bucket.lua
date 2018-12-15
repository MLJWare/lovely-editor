local PropertyStore           = require "PropertyStore"
local FillAction              = require "action.paint.Fill"

return {
    id = "tool.bucket";
    on_press = function (_, undoStack, data, px1, py1)
      local color = PropertyStore.get("core.graphics", "paint.color"):hex()
      undoStack:commit(FillAction.apply(data, px1, py1, color))
    end
  };