local assertf                 = require "assertf"
local is                      = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

---@class ImagePacket
local ImagePacket = {}
ImagePacket.__index = ImagePacket
ImagePacket._kind = ";ImagePacket;"

setmetatable(ImagePacket, {
  __call = function (_, packet)
    assert(is_table(packet), "ImagePacket constructor must be a table.")
    ImagePacket.typecheck(packet, "ImagePacket constructor")
    setmetatable(packet, ImagePacket)
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
  local value = obj.value
  local test = type(value) == "userdata"
           and type(value.type) == "function"
           and value:type() == "Canvas"
  assertf(test, "Error in %s: Missing/invalid property: 'value' must be a Canvas.", where)
end

function ImagePacket.is(obj)
  return is_metakind(obj, ";ImagePacket;")
end

return ImagePacket
