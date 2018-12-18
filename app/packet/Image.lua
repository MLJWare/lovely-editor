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

function ImagePacket.clone(obj)
  _pastee = obj.canvas
  local canvas = love.graphics.newCanvas(_pastee:getDimensions())
  canvas:renderTo(_paste)
  _pastee = nil

  return ImagePacket{
    canvas = canvas;
  }
end

function ImagePacket.typecheck(obj, where)
  Packet.typecheck(obj, where)
  local canvas = obj.canvas
  local test = type(canvas) == "userdata"
           and type(canvas.type) == "function"
           and canvas:type() == "Canvas"
  assertf(test, "Error in %s: Missing/invalid property: 'canvas' must be a Canvas.", where)
end

function ImagePacket.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";ImagePacket;")
end

return ImagePacket