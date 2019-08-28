local PropertyStore           = require "PropertyStore"
local clamp                   = require "math.clamp"
local pack_color              = require "util.color.pack"

return {
    id = "tool.picker";
    on_press = function (_, _, data, x, y)
      local w, h = data:getDimensions()
      x = clamp(math.floor(x), 0, w-1)
      y = clamp(math.floor(y), 0, h-1)
      PropertyStore.set("core.graphics", "paint.color", pack_color(data:getPixel(x, y)))
    end;
    on_drag = function (_, _, data, x, y)
      local w, h = data:getDimensions()
      x = clamp(math.floor(x), 0, w - 1)
      y = clamp(math.floor(y), 0, h - 1)
      PropertyStore.set("core.graphics", "paint.color", pack_color(data:getPixel(x, y)))
    end;
  };
