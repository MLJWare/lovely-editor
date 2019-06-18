local assertf                 = require "assertf"
local UndoStack               = require "UndoStack"
local ImagePacket             = require "packet.Image"
local is                      = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

local EditImagePacket = {}
EditImagePacket.__index = EditImagePacket
EditImagePacket._kind = ";EditImagePacket;ImagePacket;"

setmetatable(EditImagePacket, {
  __index = ImagePacket;
  __call = function (_, packet)
    assert(is_table(packet), "EditImagePacket constructor must be a table.")
    EditImagePacket.typecheck(packet, "EditImagePacket constructor")

    packet.value = love.graphics.newCanvas(packet.data:getDimensions())
    packet.image = love.graphics.newImage(packet.data)
    packet.undoStack = UndoStack()

    setmetatable(packet, EditImagePacket)
    packet:refresh()
    return packet
  end;
})

local _pastee
local function _paste()
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(_pastee)
end

function EditImagePacket:replicate(obj)
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

function EditImagePacket:refresh()
  self.image:replacePixels(self.data)
  love.graphics.setCanvas(self.value)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(self.image)
  love.graphics.setCanvas()
end

function EditImagePacket.clone(obj)
  _pastee = obj.value
  local value = love.graphics.newCanvas(_pastee:getDimensions())
  value:renderTo(_paste)
  _pastee = nil

  return EditImagePacket{
    value = value;
  }
end

function EditImagePacket.typecheck(obj, where)
  local data = obj.data
  local test = type(data) == "userdata"
           and type(data.type) == "function"
           and data:type() == "ImageData"
  assertf(test, "Error in %s: Missing/invalid property: 'data' must be an ImageData.", where)
end

function EditImagePacket.is(obj)
  return is_metakind(obj, ";EditImagePacket;")
end

return EditImagePacket
