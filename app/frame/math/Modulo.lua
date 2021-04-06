local pleasure = require "pleasure"
local BaseMathFrame = require "frame.math.BaseMath"

local font_writer             = require "util.font_writer"
local fontstore              = require "fontstore"

local font = fontstore.default[12]


local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class ModuloFrame : BaseMathFrame
local ModuloFrame = {}
ModuloFrame.__index = ModuloFrame
ModuloFrame._kind = ";ModuloFrame;BaseMathFrame;Frame;"

setmetatable(ModuloFrame, {
  __index = BaseMathFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "ModuloFrame constructor must be a table.")
    frame.size_x = frame.size_x or 40
    frame.size_y = frame.size_y or 20
    setmetatable(BaseMathFrame(frame), ModuloFrame)
    return frame
  end;
})

function ModuloFrame.is(obj)
  return is_metakind(obj, ";ModuloFrame;")
end

function ModuloFrame._calculate_value(_, left_value, right_value)
  return left_value % right_value
end

function ModuloFrame.draw_decor(_, _, _)
  love.graphics.setColor(1.0, 1.0, 1.0)
  font_writer.print_aligned(font, "mod", 0, 0, "middle", "center")
end

function ModuloFrame.serialize()
  return "ModuloFrame {}"
end

function ModuloFrame.id()
  return "Modulo"
end

return ModuloFrame
