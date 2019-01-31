local ctrl_is_down            = require "util.ctrl_is_down"
local shift_is_down           = require "util.shift_is_down"
local Frame                   = require "Frame"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local clone                   = require "pleasure.clone"
local MouseButton             = require "const.MouseButton"
local PropertyStore           = require "PropertyStore"
local ImagePacket             = require "packet.Image"
local EditImagePacket         = require "packet.EditImage"
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
    frame.image = EditImagePacket {
      data = frame.data;
    }
    frame.data = nil
    frame._own_image = frame.image
    frame.size.x, frame.size.y = frame.image.data:getDimensions()

    setmetatable(frame, PixelFrame)
    frame:refresh()
    return frame
  end;
})

PixelFrame.takes = IOs{
  {id = "image", kind = EditImagePacket};
}

PixelFrame.gives = IOs{
  {id = "image", kind = ImagePacket};
}


function PixelFrame:on_connect(prop, from)
  if prop ~= "image" then return end
  self.image = from
  from:listen(self, self.refresh)
  self:refresh()
end

function PixelFrame:on_disconnect(prop)
  if prop ~= "image" then return end
  try_invoke(self.image, "unlisten", self, self.refresh)
  self.image = self._own_image
  self:refresh()
end

function PixelFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save
  end
end

function PixelFrame:on_save()
  return self.image.data:encode("png")
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
  frame.data = clone(self.image.data)
  return PixelFrame(frame)
end

function PixelFrame:draw(size, scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.value, 0, 0, 0, scale, scale)
  try_invoke(self:tool(), "draw_hint", self.image.value, size, scale)
end

function PixelFrame:locked()
  return false
end

function PixelFrame:tool()
  return not self:locked()
      and PropertyStore.get("core.graphics", "paint.tool")
       or nil
end

function PixelFrame:refresh()
  local image = self.image
  image:refresh()
  self._own_image:inform(image)
end

function PixelFrame:refresh_internal()
  local image = self.image
  if image ~= self._own_image then
    image:inform_except(self)
  end
  self:refresh()
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
  self.image.undoStack:undo(self.image.data)
  self:refresh_internal()
end

function PixelFrame:redo()
  if self:locked() then return end
  self.image.undoStack:redo(self.image.data)
  self:refresh_internal()
end

function PixelFrame:mousepressed(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  self:request_focus()

  local tool = self:tool()
  if not tool then return end

  try_invoke(tool, "on_press", self.image.undoStack, self.image.data, mx, my)
  self:refresh_internal()
end

function PixelFrame:mousedragged1(mx, my, dx, dy)
  local tool = self:tool()
  if not tool then return end

  local mx2 = mx - dx
  local my2 = my - dy

  try_invoke(tool, "on_drag", self.image.undoStack, self.image.data, mx, my, mx2, my2)
  self:refresh_internal()
end

function PixelFrame:mousereleased(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  local tool = self:tool()
  if not tool then return end

  try_invoke(tool, "on_release", self.image.undoStack, self.image.data, mx, my)
  self:refresh_internal()
end

function PixelFrame:id()
  local filename = self.filename
  if filename then
    return filename:match("[^/]*$")
  end
  return Frame.id(self)
end

function PixelFrame:serialize()
  local encoded_data = love.data.encode("string", "base64", self.image.data:encode("png"), 80)
  return ([=[PixelFrame {
    data = imagedata [[
%s]];
  }]=]):format(encoded_data)
end

return PixelFrame
