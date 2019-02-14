local ctrl_is_down            = require "util.ctrl_is_down"
local shift_is_down           = require "util.shift_is_down"
local Frame                   = require "Frame"
local assertf                 = require "assertf"
local clone                   = require "pleasure.clone"
local MouseButton             = require "const.MouseButton"
local PropertyStore           = require "PropertyStore"
local Signal                  = require "Signal"
local ImageKind               = require "Kind.Image"
local EditImageKind           = require "Kind.EditImage"
local EditImage               = require "packet.EditImage"
local IOs                     = require "IOs"
local try_invoke              = require "pleasure.try".invoke

local PixelFrame = {}
PixelFrame.__index = PixelFrame

PixelFrame._kind = ";PixelFrame;Frame;"

setmetatable(PixelFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "PixelFrame constructor must be a table.")
    frame.size_x = frame.size_x or 0
    frame.size_y = frame.size_y or 0

    PixelFrame.typecheck(frame, "PixelFrame constructor")
    frame.image = EditImage {
      data = frame.data;
    }
    frame.signal_out = Signal {
      kind = ImageKind;
      on_connect = function ()
        return frame.image_edit
      end;
    }
    frame.image_edit = frame.image
    frame.data = nil
    frame.size_x, frame.size_y = frame.image.data:getDimensions()

    setmetatable(frame, PixelFrame)
    frame:refresh()
    return frame
  end;
})

PixelFrame.takes = IOs{
  {id = "signal_in", kind = EditImageKind};
}

PixelFrame.gives = IOs{
  {id = "signal_out", kind = ImageKind};
}


function PixelFrame:on_connect(prop, from, data)
  if prop ~= "signal_in" then return end
  self.signal_in = from
  from:listen(self, prop, self.refresh)
  self:refresh(prop, data)
end

function PixelFrame:on_disconnect(prop)
  if prop ~= "signal_in" then return end
  try_invoke(self.signal_in, "unlisten", self, prop, self.refresh)
  self.signal_in = nil
  self:refresh(prop, nil)
end

function PixelFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save
  end
end

function PixelFrame:on_save()
  return self.image_edit.data:encode("png")
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
  frame.data = clone(self.image_edit.data)
  return PixelFrame(frame)
end

function PixelFrame:draw(size_x, size_y, scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image_edit.value, 0, 0, 0, scale, scale)
  try_invoke(self:tool(), "draw_hint", self.image_edit.value, size_x, size_y, scale)
end

function PixelFrame.tool()
  return PropertyStore.get("core.graphics", "paint.tool")
end

function PixelFrame:refresh(_, data)
  local image = data or self.image
  self.image_edit = image
  image:refresh() -- QUESTION is this correct?
  self.signal_out:inform(image)
end

function PixelFrame:refresh_internal()
  local image = self.image_edit
  if image ~= self.image then
    --image:inform_except(self) -- FIXME!!!!!
  end
  self:refresh(image)
end

function PixelFrame:keypressed(key)
  if not ctrl_is_down() then return end
  if key ~= "z" then return end

  if shift_is_down() then
    self:redo()
  else
    self:undo()
  end
end

function PixelFrame:undo()
  self.image_edit.undoStack:undo(self.image_edit.data)
  self:refresh_internal()
end

function PixelFrame:redo()
  self.image_edit.undoStack:redo(self.image_edit.data)
  self:refresh_internal()
end

function PixelFrame:mousepressed(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  self:request_focus()

  local tool = self:tool()
  if not tool then return end

  try_invoke(tool, "on_press", self.image_edit.undoStack, self.image_edit.data, mx, my)
  self:refresh_internal()
end

function PixelFrame:mousedragged1(mx, my, dx, dy)
  local tool = self:tool()
  if not tool then return end

  local mx2 = mx - dx
  local my2 = my - dy

  try_invoke(tool, "on_drag", self.image_edit.undoStack, self.image_edit.data, mx, my, mx2, my2)
  self:refresh_internal()
end

function PixelFrame:mousereleased(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  local tool = self:tool()
  if not tool then return end

  try_invoke(tool, "on_release", self.image_edit.undoStack, self.image_edit.data, mx, my)
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
  local encoded_data = love.data.encode("string", "base64", self.image_edit.data:encode("png"), 80)
  return ([=[PixelFrame {
    data = imagedata [[
%s]];
  }]=]):format(encoded_data)
end

return PixelFrame
