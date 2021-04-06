local pleasure = require "pleasure"
local BaseMathFrame = require "frame.math.BaseMath"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class MultiplyFrame : BaseMathFrame
local MultiplyFrame = {}
MultiplyFrame.__index = MultiplyFrame
MultiplyFrame._kind = ";MultiplyFrame;BaseMathFrame;Frame;"

setmetatable(MultiplyFrame, {
  __index = BaseMathFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "MultiplyFrame constructor must be a table.")
    setmetatable(BaseMathFrame(frame), MultiplyFrame)
    return frame
  end;
})

function MultiplyFrame.is(obj)
  return is_metakind(obj, ";MultiplyFrame;")
end

function MultiplyFrame._calculate_value(_, left_value, right_value)
  return left_value * right_value
end

function MultiplyFrame.draw_decor(_, size_x, size_y)
  local half_x = size_x/2
  local half_y = size_y/2
  love.graphics.rotate(math.pi/4)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", -0.1 * half_x, -0.7 * half_y, 0.2 * half_x, 1.4 * half_y);
  love.graphics.rectangle("fill", -0.7 * half_x, -0.1 * half_y, 1.4 * half_x, 0.2 * half_y);
end

function MultiplyFrame.serialize()
  return "MultiplyFrame {}"
end

function MultiplyFrame.id()
  return "Multiply"
end

return MultiplyFrame
