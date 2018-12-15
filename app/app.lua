local vec2                    = require "linear-algebra.Vector2"
local Viewport                = require "Viewport"

local app = {
  viewport = Viewport {
    pos    = vec2(0, 0);
    scale  = 1;
  };
  views = {};
}

return app