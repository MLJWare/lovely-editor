local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberPacket            = require "packet.Number"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"

local font = love.graphics.newFont(12)

local TickerFrame = {}
TickerFrame.__index = TickerFrame

TickerFrame._kind = ";TickerFrame;Frame;"

setmetatable(TickerFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "TickerFrame constructor must be a table.")

    if not frame.size then frame.size = vec2(64, 20) end
    TickerFrame.typecheck(frame, "TickerFrame constructor")

    frame.value = NumberPacket{ value = 0 }
    frame._delta = 0

    setmetatable(Frame(frame), TickerFrame)
    return frame
  end;
})

function TickerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberPacket.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be an Ticker.", where)
end

function TickerFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";TickerFrame;")
end

TickerFrame.gives = IOs{
  {id = "value", kind = NumberPacket};
}

local SPT = 1/60

function TickerFrame:update(dt)
  local delta = self._delta + dt
  if delta >= SPT then
    delta = delta - SPT
    self.value.value = self.value.value + 1
    self:refresh()
  end
  self._delta = delta
end
function TickerFrame:draw(size, scale)
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

function TickerFrame:refresh()
  self.value:inform()
end

function TickerFrame.id()
  return "Ticker"
end

function TickerFrame:serialize()
  return "TickerFrame {}"
end

return TickerFrame
