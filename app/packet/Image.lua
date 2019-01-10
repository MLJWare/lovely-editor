local Packet = require "Packet"
local assertf = require "assertf"

local ImagePacket = {}
ImagePacket.__index = ImagePacket

ImagePacket._kind = ";ImagePacket;Packet;"

setmetatable(ImagePacket, {
  __index = Packet;
  __call = function (_, packet)
    assert(type(packet) == "table", "ImagePacket constructor must be a table.")
    ImagePacket.typecheck(packet, "ImagePacket constructor")
    setmetatable(Packet(packet), ImagePacket)
    return packet
  end;
})

local _pastee
local function _paste()
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(_pastee)
end

function ImagePacket:replicate(obj)
  self.value:release()
  local obj_canvas = obj.value
  local new_canvas = love.graphics.newCanvas(obj_canvas:getDimensions())
  love.graphics.setCanvas(new_canvas)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(obj_canvas)
  love.graphics.setCanvas()
  self.value = new_canvas
end

function ImagePacket.clone(obj)
  _pastee = obj.value
  local value = love.graphics.newCanvas(_pastee:getDimensions())
  value:renderTo(_paste)
  _pastee = nil

  return ImagePacket{
    value = value;
  }
end

function ImagePacket.typecheck(obj, where)
  Packet.typecheck(obj, where)
  local value = obj.value
  local test = type(value) == "userdata"
           and type(value.type) == "function"
           and value:type() == "Canvas"
  assertf(test, "Error in %s: Missing/invalid property: 'value' must be a Canvas.", where)
end

function ImagePacket.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";ImagePacket;")
end

do
  local pixel = love.graphics.newImage(love.image.newImageData(1, 1))
  pixel:setWrap("repeat", "repeat")
  function ImagePacket.default_raw_value()
    return pixel
  end
end

return ImagePacket
