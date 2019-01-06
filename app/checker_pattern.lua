local repeat_shader           = require "shader.repeat"
local shader_fill             = require "shader_fill"

local checker_pattern
do
  local data = love.image.newImageData(2, 2)
  data:mapPixel(function (x, y)
    return 1, 1, 1, (x + y)%2
  end)
  checker_pattern = love.graphics.newImage(data)
  checker_pattern:setWrap("repeat", "repeat")
  checker_pattern:setFilter("nearest", "nearest", 0)
end

return function (x, y, width, height, scale)
  repeat_shader:send("image", checker_pattern)
  repeat_shader:send("scale", 2*(scale or 1))
  shader_fill(repeat_shader, x, y, width, height)
end
