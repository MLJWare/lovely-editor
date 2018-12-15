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
    packet.image = love.graphics.newImage(packet.data)
    return packet
  end;
})

function ImagePacket.clone(obj)
  return ImagePacket{
    data = obj.data:clone();
  }
end

function ImagePacket.typecheck(obj, where)
  Packet.typecheck(obj, where)
  local data = obj.data
  local test = type(data) == "userdata"
           and type(data.type) == "function"
           and data:type() == "ImageData"
  assertf(test, "Error in %s: Missing/invalid property: 'data' must be an ImageData.", where)
end

function ImagePacket.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";ImagePacket;")
end

return ImagePacket