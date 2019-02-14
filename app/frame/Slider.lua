local Frame                   = require "Frame"
local clamp                   = require "math.clamp"
local MouseButton             = require "const.MouseButton"
local Signal                  = require "Signal"
local NumberKind              = require "Kind.Number"
local IOs                     = require "IOs"

local SliderFrame = {}
SliderFrame.__index = SliderFrame

SliderFrame._kind = ";SliderFrame;Frame;"

setmetatable(SliderFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "SliderFrame constructor must be a table.")
    frame.size_x = frame.size_x or 32
    frame.size_y = frame.size_y or 128

    SliderFrame.typecheck(frame, "SliderFrame constructor")
    frame.pct = frame.pct or 0
    frame.signal_out = Signal {
      kind = NumberKind;
      on_connect = function ()
        return frame.pct
      end;
    }
    setmetatable(frame, SliderFrame)

    return frame
  end;
})

SliderFrame.gives = IOs {
  {id = "signal_out", kind = NumberKind}
}

function SliderFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function SliderFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";SliderFrame;")
end

local knob_h = 8
function SliderFrame:draw(size_x, size_y, _)
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)

  love.graphics.push()

  local knob_y = math.floor( (1 - self.pct)*size_y - knob_h/2)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle( "fill", 0, knob_y, size_x, knob_h)
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.rectangle( "line", 0.5, knob_y + 0.5, size_x - 1, knob_h - 1)

  love.graphics.pop()
end

function SliderFrame:refresh()
  self.signal_out:inform(self.pct)
end

function SliderFrame:mousepressed(_, my, button)
  if button ~= MouseButton.LEFT then return end
  self.pct = clamp(1 - my/self.size_y, 0, 1)
  self:refresh()
end
--[[
function SliderFrame:mousereleased(_, _, button)
  if button ~= 1 then return end
end
--]]
function SliderFrame:mousedragged1(_, my, _, _)
  self.pct = clamp(1 - my/self.size_y, 0, 1)
  self:refresh()
end

function SliderFrame:serialize()
  return ([[SliderFrame {
    pct = %s;
  }]]):format(self.pct)
end

return SliderFrame
