local Frame                   = require "Frame"
local Signal                  = require "Signal"
local NumberKind              = require "Kind.Number"
local IOs                     = require "IOs"
local is                      = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

local ToggleFrame = {}
ToggleFrame.__index = ToggleFrame
ToggleFrame._kind = ";ToggleFrame;Frame;"

setmetatable(ToggleFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "ToggleFrame constructor must be a table.")
    frame.size_x = frame.size_x or 48
    frame.size_y = frame.size_y or 24

    ToggleFrame.typecheck(frame, "ToggleFrame constructor")
    frame.pressed = frame.pressed or false
    frame.signal_out = Signal {
      kind = NumberKind;
      on_connect = function ()
        return frame.pressed and 1 or 0
      end;
    }
    setmetatable(frame, ToggleFrame)

    return frame
  end;
})

ToggleFrame.gives = IOs {
  {id = "signal_out", kind = NumberKind}
}

function ToggleFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ToggleFrame.is(obj)
  return is_metakind(obj, ";ToggleFrame;")
end

function ToggleFrame:draw(size_x, size_y, _)

  love.graphics.push()
  love.graphics.setLineStyle("smooth")

  local toggle_x, toggle_y, rounding

  if size_x < size_y then
    rounding = size_x / 2
    toggle_x = rounding
    toggle_y = self.pressed and size_y - rounding or rounding
  else
    rounding = size_y / 2
    toggle_x = self.pressed and size_x - rounding or rounding
    toggle_y = rounding
  end
  local toggle_r = math.max(1, 0.8 * rounding)

  if self.pressed then
    love.graphics.setColor(0.1, 0.8, 0.2)
  else
    love.graphics.setColor(0.6, 0.6, 0.6)
  end
  love.graphics.rectangle("fill", 0, 0, size_x, size_y, rounding)
  love.graphics.rectangle("line", 0, 0, size_x, size_y, rounding)

  love.graphics.setColor(1, 1, 1)
  love.graphics.circle( "fill", toggle_x, toggle_y, toggle_r)
  love.graphics.circle( "line", toggle_x, toggle_y, toggle_r)
  love.graphics.pop()
end

function ToggleFrame:refresh()
  self.signal_out:inform(self.pressed and 1 or 0)
end

function ToggleFrame:mousepressed(_, my, button)
  if button ~= 1 then return end
  self.pressed = not self.pressed
  self:refresh()
end
--[[
function ToggleFrame:mousereleased(_, _, button)
  if button ~= 1 then return end
end
--]]
-- function ToggleFrame:mousedragged1(_, my, _, _)
--   self.pct = clamp(1 - my/self.size_y, 0, 1)
--   self:refresh()
-- end

function ToggleFrame:serialize()
  return ([[ToggleFrame {
    pressed = %s;
  }]]):format(self.pressed)
end

return ToggleFrame
