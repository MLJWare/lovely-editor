local ImagePacket = require "packet.Image"

local default = love.graphics.newImage(love.image.newImageData(1, 1))
default:setWrap("repeat", "repeat")

local is = ImagePacket.is

return {
  name = "Image";
  is = is;
  to_shader_value = function (data)
    return is(data) and data.value or default
  end;
}

