local PropertyStore           = require "PropertyStore"
local clamp                   = require "math.clamp"
local pack_color              = require "util.color.pack"

return {
    id = "tool.picker";
    on_press = function (_, _, data, x, y)
      x = math.floor(x)
      y = math.floor(y)
      PropertyStore.set("core.graphics", "paint.color", pack_color(data:getPixel(x, y)))
    end;
    on_drag = function (_, _, data, x, y)
      x = clamp(math.floor(x), 0, data:getWidth () - 1)
      y = clamp(math.floor(y), 0, data:getHeight() - 1)
      PropertyStore.set("core.graphics", "paint.color", pack_color(data:getPixel(x, y)))
    end;
  };
