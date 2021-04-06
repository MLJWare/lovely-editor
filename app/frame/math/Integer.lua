local integer_filter          = require "input.filter.integer"
local NumberFrame              = require "frame.math.Number"
local pleasure                = require "pleasure"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local IntegerFrame = {}
IntegerFrame.__index = IntegerFrame
IntegerFrame._kind = ";IntegerFrame;NumberFrame;InputFrame;Frame;"

setmetatable(IntegerFrame, {
  __index = NumberFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "IntegerFrame constructor must be a table.")
    frame = NumberFrame(frame)
    IntegerFrame.typecheck(frame, "IntegerFrame constructor")

    local value = math.floor(frame.value)
    frame.value = value

    frame._edit.filter = integer_filter
    frame._edit.text = tostring(value)

    setmetatable(frame, IntegerFrame)
    return frame
  end;
})

function IntegerFrame.is(obj)
  return is_metakind(obj, ";IntegerFrame;")
end

function IntegerFrame:refresh(_, data_in)
  local new_value = math.floor(tonumber(data_in or self._edit.text) or 0)
  if self.value == new_value then return end
  self.value = new_value
  self.signal_out:inform(new_value)
end

function IntegerFrame:serialize()
  return ([[IntegerFrame {
    value = %s;
  }]]):format(tostring(self.value))
end

function IntegerFrame.id()
  return "Integer"
end

return IntegerFrame
