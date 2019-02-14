local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Signal                  = require "Signal"
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

    frame._delta = 0
    frame.value = math.floor(frame.value or 0)

    frame.signal_out = Signal {
      kind  = NumberKind;
      on_connect = function ()
        return frame.value
      end;
    }

    setmetatable(Frame(frame), TimerFrame)
    return frame
  end;
})

function TimerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberKind.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be a number.", where)
end

function TimerFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";TimerFrame;")
end

TimerFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

local SPT = 1

function TimerFrame:update(dt)
  local delta = self._delta + dt
  if delta >= SPT then
    delta = delta - SPT
    local value = self.value + 1
    self.value = value
    self:refresh(value)
  end
  self._delta = delta
end

function TimerFrame:draw(size, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)
  local text = tostring(self.value)
  pleasure.push_region(0, 0, size.x, size.y)
  pleasure.scale(scale)
  do
    local center_y = size.y/2/scale
    love.graphics.setColor(0.0, 0.0, 0.0)
    font_writer.print_aligned(font, text, 0, center_y, "left", "center")
  end
  pleasure.pop_region()
end

function TimerFrame:refresh(data)
  self.signal_out:inform(data)
end

function TimerFrame.id()
  return "Timer"
end

function TimerFrame.serialize()
  return "TimerFrame {}"
end

return TimerFrame
