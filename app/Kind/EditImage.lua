local EditImagePacket = require "packet.EditImage"

local default = love.graphics.newImage(love.image.newImageData(1, 1))
default:setWrap("repeat", "repeat")

local is = EditImagePacket.is

return {
  is = is;
  to_shader_value = function (data)
    return is(data) and data.value or default
  end;
}
