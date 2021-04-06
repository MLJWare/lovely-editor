local pleasure = require "pleasure"
local BaseMathFrame = require "frame.math.BaseMath"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class SubtractFrame : BaseMathFrame
local SubtractFrame = {}
SubtractFrame.__index = SubtractFrame
SubtractFrame._kind = ";SubtractFrame;BaseMathFrame;Frame;"

setmetatable(SubtractFrame, {
  __index = BaseMathFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "SubtractFrame constructor must be a table.")
    setmetatable(BaseMathFrame(frame), SubtractFrame)
    return frame
  end;
})

function SubtractFrame.is(obj)
  return is_metakind(obj, ";SubtractFrame;")
end

function SubtractFrame._calculate_value(_, left_value, right_value)
  return left_value - right_value
end

function SubtractFrame.draw_decor(_, size_x, size_y)
  local half_x = size_x/2
  local half_y = size_y/2
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", -0.7 * half_x, -0.1 * half_y, 1.4 * half_x, 0.2 * half_y);
end

function SubtractFrame.serialize()
  return "SubtractFrame {}"
end

function SubtractFrame.id()
  return "Subtract"
end

return SubtractFrame
