local pleasure = require "pleasure"
local BaseMathFrame = require "frame.math.BaseMath"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class DivideFrame : BaseMathFrame
local DivideFrame = {}
DivideFrame.__index = DivideFrame
DivideFrame._kind = ";DivideFrame;BaseMathFrame;Frame;"

setmetatable(DivideFrame, {
  __index = BaseMathFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "DivideFrame constructor must be a table.")
    setmetatable(BaseMathFrame(frame), DivideFrame)
    return frame
  end;
})

function DivideFrame.is(obj)
  return is_metakind(obj, ";DivideFrame;")
end

function DivideFrame._calculate_value(_, left_value, right_value)
  return left_value / right_value
end



function DivideFrame.draw_decor(_, size_x, size_y)
  local half_x = size_x/2
  local half_y = size_y/2
  love.graphics.rotate(math.pi/7)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", -0.1 * half_x, -0.7 * half_y, 0.2 * half_x, 1.4 * half_y);
end

function DivideFrame.serialize()
  return "DivideFrame {}"
end

function DivideFrame.id()
  return "Divide"
end

return DivideFrame
