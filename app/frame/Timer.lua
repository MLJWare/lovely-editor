local Frame                   = require "Frame"
local IOs                     = require "IOs"
local Integer                 = require "packet.Integer"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"

local font = love.graphics.newFont(12)

local TimerFrame = {}
TimerFrame.__index = TimerFrame

TimerFrame._kind = ";TimerFrame;Frame;"

setmetatable(TimerFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "TimerFrame constructor must be a table.")

    if not frame.size then frame.size = vec2(64, 20) end
    TimerFrame.typecheck(frame, "TimerFrame constructor")

    if not frame.value then
      frame.value = Integer{ value = 0 }
    end

    frame._delta = 0

    setmetatable(Frame(frame), TimerFrame)
    return frame
  end;
})

function TimerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or Integer.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be an Timer.", where)
end

function TimerFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";TimerFrame;")
end

TimerFrame.gives = IOs{
  {id = "value", kind = Integer};
}

function TimerFrame:update(dt)
  self._delta = self._delta + dt
  if self._delta >= 1 then
    self._delta = self._delta - 1
    self.value.value = self.value.value + 1
    self:refresh()
  end
end
function TimerFrame:draw(size, scale)
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

function TimerFrame:refresh()
  self.value:inform()
end

function TimerFrame.id()
  return "Timer"
end

return TimerFrame