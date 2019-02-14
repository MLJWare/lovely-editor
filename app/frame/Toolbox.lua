local Frame                   = require "Frame"
local Images                  = require "Images"
local PropertyStore           = require "PropertyStore"
local Toolbox                 = require "Toolbox"
local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"
local Vector4Kind             = require "Kind.Vector4"
local vec2                    = require "linear-algebra.Vector2"

local try_invoke              = require "pleasure.try".invoke

local IOs                     = require "IOs"

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
    assert(type(frame) == "table", "ToolboxFrame constructor must be a table.")
    if not frame.size then
      frame.size = vec2(PAD + (#Toolbox + 1)*BTN_OFFSET_X, PAD + BTN_OFFSET_Y);
    end
    ToolboxFrame.typecheck(frame, "ToolboxFrame constructor")
    setmetatable(frame, ToolboxFrame)
    return frame
  end;
})

function ToolboxFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ToolboxFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ToolboxFrame;")
end

ToolboxFrame.takes = IOs {
  {id = "signal_color", kind = Vector4Kind}
}

function ToolboxFrame:on_connect(prop, from, data)
  if prop ~= "signal_color" then return end
  self.signal_color = from
  from:listen(self, prop, self.refresh_color)
  self:refresh_color(data)
end

function ToolboxFrame:on_disconnect(prop)
  if prop ~= "signal_color" then return end
  try_invoke(self.signal_color, "unlisten", self, prop, self.refresh_color)
  self.signal_color = nil
end

function ToolboxFrame:refresh_color(data)
  local color = pack_color(data[1], data[2], data[3], data[4])
  PropertyStore.set("core.graphics", "paint.color", color)
end

function ToolboxFrame:buttons()
  local rows = math.floor((self.size.x - PAD)/BTN_OFFSET_X)

  return coroutine.wrap(function()
    for i = 0, #Toolbox - 1 do
      local x =           ((i + 1)%rows)*BTN_OFFSET_X + PAD
      local y = math.floor(i/rows)*BTN_OFFSET_Y + PAD
      coroutine.yield(i + 1, x, y)
    end
  end)
end

local function get_rgba()
  return unpack_color(PropertyStore.get("core.graphics", "paint.color"))
end

function ToolboxFrame.draw(self, size, scale)
  local width, height = size.x, size.y

  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.push()
  love.graphics.scale(scale)

  love.graphics.setColor(get_rgba())
  love.graphics.rectangle("fill", PAD, PAD, BTN_WIDTH, BTN_HEIGHT)

  for i, x, y in self:buttons() do
    self:_draw_button(i, x, y)
  end
  love.graphics.pop()
end

function ToolboxFrame._draw_button(_, index, x, y)
  local tool = Toolbox[index]
  local active = PropertyStore.get("core.graphics", "paint.tool") == tool
  if active then
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

  for index, x, y in self:buttons() do
    if btn_contains(x, y, mx, my) then
      PropertyStore.set("core.graphics", "paint.tool", Toolbox[index])
      break
    end
  end
end

function ToolboxFrame.mousereleased(_, _, _, button)
  if button ~= 1 then return end
end

function ToolboxFrame.mousemoved(_, _, _, _, _)
end

function ToolboxFrame:serialize()
  return "ToolboxFrame {}"
end

return ToolboxFrame
