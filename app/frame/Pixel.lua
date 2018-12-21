local ctrl_is_down            = require "util.ctrl_is_down"
local shift_is_down           = require "util.shift_is_down"
local Frame                   = require "Frame"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local clone                   = require "pleasure.clone"
local MouseButton             = require "const.MouseButton"
local PropertyStore           = require "PropertyStore"
local UndoStack               = require "UndoStack"
local ImagePacket             = require "packet.Image"
local IOs                     = require "IOs"
local try_invoke              = require "pleasure.try".invoke

local PixelFrame = {}
PixelFrame.__index = PixelFrame

PixelFrame._kind = ";PixelFrame;Frame;"

setmetatable(PixelFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "PixelFrame constructor must be a table.")
    if not frame.size then
      frame.size = vec2()
    end
    PixelFrame.typecheck(frame, "PixelFrame constructor")
    frame.image = ImagePacket{
      canvas = love.graphics.newCanvas(frame.data:getDimensions())
    }
    frame._own_image = frame.image
    frame.size.x, frame.size.y = frame.data:getDimensions()
    frame.data_image = love.graphics.newImage(frame.data)

    frame._undoStack = UndoStack()

    setmetatable(frame, PixelFrame)
    frame:refresh()
    return frame
  end;
})

PixelFrame.gives = IOs{
  {id = "image", kind = ImagePacket};
}
PixelFrame.takes = IOs{
  {id = "image", kind = ImagePacket};
}

function PixelFrame:on_connect(prop, from)
  if prop == "image" then
    self.image = from
    self:refresh()
  end
end

function PixelFrame:on_disconnect(prop)
  if prop == "image" then
    try_invoke(self.image, "unlisten", self)
    self.image = self._own_image
    self:refresh()
  end
end

function PixelFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(type(obj.data) == "userdata"
      and type(obj.data.type) == "function"
      and obj.data:type() == "ImageData", "Error in %s: Missing/invalid property: 'data' must be an ImageData.", where)
end

function PixelFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";PixelFrame;")
end

function PixelFrame:clone()
  local frame = Frame.clone(self)
  frame.data = clone(self.data)
  return PixelFrame(frame)
end

function PixelFrame:draw(size, scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.canvas, 0, 0, 0, scale, scale)
  try_invoke(self:tool(), "draw_hint", self.image.canvas, size, scale)
end

function PixelFrame:locked()
  return self.image ~= self._own_image
end

function PixelFrame:tool()
  return not self:locked()
      and PropertyStore.get("core.graphics", "paint.tool")
       or nil
end

local _paste_self = nil
local function _paste()
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(_paste_self.data_image)
end

function PixelFrame:refresh()
  self.data_image:replacePixels(self.data)
  _paste_self = self
  self.image.canvas:renderTo(_paste)
  _paste_self = nil
  self.image:inform()
end

function PixelFrame:keypressed(key)
  if self:locked() then return end
  if not ctrl_is_down() then return end
  if key ~= "z" then return end

  if shift_is_down() then
    self:redo()
  else
    self:undo()
  end
end

function PixelFrame:undo()
  if self:locked() then return end
  self._undoStack:undo(self.data)
  self:refresh()
end

function PixelFrame:redo()
  if self:locked() then return end
  self._undoStack:redo(self.data)
  self:refresh()
end

function PixelFrame:mousepressed(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  self:request_focus()

  local tool = self:tool()
  if not tool then return end

  try_invoke(tool, "on_press", self._undoStack, self.data, mx, my)
  self:refresh()
end

function PixelFrame:mousedragged1(mx, my, dx, dy)
  local tool = self:tool()
  if not tool then return end

  local mx2 = mx - dx
  local my2 = my - dy

  try_invoke(tool, "on_drag", self._undoStack, self.data, mx, my, mx2, my2)
  self:refresh()
end

function PixelFrame:mousereleased(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  local tool = self:tool()
  if not tool then return end

  try_invoke(tool, "on_release", self._undoStack, self.data, mx, my)
  self:refresh()
end

function PixelFrame:id()
  local filename = self.filename
  if filename then
    return filename:match("[^/]*$")
  end
  return Frame.id(self)
end

return PixelFrame