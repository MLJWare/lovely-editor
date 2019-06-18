local Frame                   = require "Frame"
local Images                  = require "Images"
local PropertyStore           = require "PropertyStore"
local Toolbox                 = require "Toolbox"
local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"
local Vector4Kind             = require "Kind.Vector4"
local pleasure                = require "pleasure"
local IOs                     = require "IOs"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local PAD = 4

local BTN_WIDTH  = 32
local BTN_HEIGHT = 32

local BTN_OFFSET_X = BTN_WIDTH  + PAD
local BTN_OFFSET_Y = BTN_HEIGHT + PAD

local ToolboxFrame = {}
ToolboxFrame.__index = ToolboxFrame
ToolboxFrame._kind = ";ToolboxFrame;Frame;"

setmetatable(ToolboxFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "ToolboxFrame constructor must be a table.")
    frame.size_x = frame.size_x or PAD + (#Toolbox + 1)*BTN_OFFSET_X
    frame.size_y = frame.size_y or PAD + BTN_OFFSET_Y;

    ToolboxFrame.typecheck(frame, "ToolboxFrame constructor")
    setmetatable(frame, ToolboxFrame)
    return frame
  end;
})

function ToolboxFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ToolboxFrame.is(obj)
  return is_metakind(obj, ";ToolboxFrame;")
end

ToolboxFrame.takes = IOs {
  {id = "signal_color", kind = Vector4Kind}
}

function ToolboxFrame:on_connect(prop, from, r, g, b, a)
  if prop ~= "signal_color" then return end
  self.signal_color = from
  from:listen(self, prop, self.refresh_color)
  self:refresh_color(prop, r, g, b, a)
end

function ToolboxFrame:on_disconnect(prop)
  if prop ~= "signal_color" then return end
  try_invoke(self.signal_color, "unlisten", self, prop, self.refresh_color)
  self.signal_color = nil
end

function ToolboxFrame.refresh_color(_, _, r, g, b, a)
  local color = pack_color(r or 0, g or 0, b or 0, a or 1)
  PropertyStore.set("core.graphics", "paint.color", color)
end

local function get_rgba()
  return unpack_color(PropertyStore.get("core.graphics", "paint.color"))
end

function ToolboxFrame:draw(size_x, size_y, scale)
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)

  love.graphics.push()
  love.graphics.scale(scale)

  love.graphics.setColor(get_rgba())
  love.graphics.rectangle("fill", PAD, PAD, BTN_WIDTH, BTN_HEIGHT)

  local active_tool = PropertyStore.get("core.graphics", "paint.tool")
  local rows = math.floor((self.size_x - PAD)/BTN_OFFSET_X)
  for i = 1, #Toolbox do
    local x = (i%rows)*BTN_OFFSET_X + PAD
    local y = math.floor((i-1)/rows)*BTN_OFFSET_Y + PAD
    self:_draw_button(i, x, y, active_tool)
  end
  love.graphics.pop()
end

function ToolboxFrame._draw_button(_, index, x, y, active_tool)
  local tool = Toolbox[index]
  if active_tool == tool then
    love.graphics.setColor(1, 1, 1)
    Images.draw("button-pressed", x, y)
    Images.draw(tool.id, x, y)
  else
    love.graphics.setColor(0.7, 0.7, 0.7)
    Images.draw("button", x, y)
    Images.draw(tool.id, x, y)
  end
end

local function btn_contains(x, y, mx, my)
  return x <= mx and mx < x + BTN_WIDTH
     and y <= my and my < y + BTN_HEIGHT
end

function ToolboxFrame:mousepressed(mx, my, button)
  if button ~= 1 then return end

  local rows = math.floor((self.size_x - PAD)/BTN_OFFSET_X)
  for index = 1, #Toolbox do
    local x = (index%rows)*BTN_OFFSET_X + PAD
    local y = math.floor((index-1)/rows)*BTN_OFFSET_Y + PAD
    if btn_contains(x, y, mx, my) then
      PropertyStore.set("core.graphics", "paint.tool", Toolbox[index])
      return
    end
  end
end

function ToolboxFrame.mousereleased(_, _, _, button)
  if button ~= 1 then return end
end

function ToolboxFrame.mousemoved(_, _, _, _, _)
end

function ToolboxFrame.serialize()
  return "ToolboxFrame {}"
end

return ToolboxFrame
