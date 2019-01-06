local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberPacket            = require "packet.Number"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"

local font = love.graphics.newFont(12)

local SumFrame = {}
SumFrame.__index = SumFrame

SumFrame._kind = ";SumFrame;Frame;"

setmetatable(SumFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "SumFrame constructor must be a table.")

    if not frame.size then frame.size = vec2(64, 20) end
    SumFrame.typecheck(frame, "SumFrame constructor")

    if not frame.value then
      frame.value = NumberPacket{ value = 0 }
    end

    setmetatable(Frame(frame), SumFrame)
    return frame
  end;
})

function SumFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberPacket.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be a NumberPacket.", where)
end

function SumFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";SumFrame;")
end

SumFrame.takes = IOs{
  {id = "left" , kind = NumberPacket};
  {id = "right", kind = NumberPacket};
}


SumFrame.gives = IOs{
  {id = "value", kind = NumberPacket};
}

function SumFrame:on_connect(prop, from)
  if prop == "left" then
    self.left = from
    from:listen(self, self.refresh)
    self:refresh()
  elseif prop == "right" then
    self.right = from
    from:listen(self, self.refresh)
    self:refresh()
  end
end

function SumFrame:on_disconnect(prop)
  if prop == "left" then
    self.left:unlisten(self, self.refresh)
    self.left = nil
    self:refresh()
  elseif prop == "right" then
    self.right:unlisten(self, self.refresh)
    self.right = nil
    self:refresh()
  end
end

function SumFrame:draw(size, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)
  local text = tostring(self.value.value)
  pleasure.push_region(0, 0, size.x, size.y)
  pleasure.scale(scale)
  do
    local center_y = size.y/2/scale
    love.graphics.setColor(0.0, 0.0, 0.0)
    font_writer.print_aligned(font, text, 0, center_y, "left", "center")
  end
  pleasure.pop_region()
end

local function _num(v)
  return v and tonumber(v.value) or 0
end

function SumFrame:refresh()
  self.value.value = _num(self.left) + _num(self.right)
  self.value:inform()
end

function SumFrame.id()
  return "Sum"
end

return SumFrame
