local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local assertf                 = require "assertf"
local number_filter           = require "input.filter.number"
local InputFrame              = require "frame.Input"
local pleasure                = require "pleasure"

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class NumberFrame : InputFrame
---@field value number
local NumberFrame = {}
NumberFrame.__index = NumberFrame
NumberFrame._kind = ";NumberFrame;InputFrame;Frame;"

setmetatable(NumberFrame, {
  __index = InputFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "NumberFrame constructor must be a table.")
    frame = InputFrame(frame)

    NumberFrame.typecheck(frame, "NumberFrame constructor")

    frame.signal_out.kind = NumberKind

    local value = tonumber(frame.value) or 0
    frame.value = value

    frame._edit.filter = number_filter
    frame._edit.text = tostring(value)
    frame._edit.hint = "0"

    setmetatable(frame, NumberFrame)
    return frame
  end;
})

function NumberFrame.typecheck(obj, where)
  InputFrame.typecheck(obj, where)
  assertf(is_opt(obj.value, NumberKind.is), "Error in %s: Invalid optional property: 'value' must be a number.", where)
end

function NumberFrame.is(obj)
  return is_metakind(obj, ";NumberFrame;")
end

NumberFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

NumberFrame.takes = IOs{
  {id = "signal_in", kind = NumberKind};
}

function NumberFrame:refresh(_, data_in)
  local new_value = tonumber(data_in or self._edit.text) or 0
  if self.value == new_value then return end
  self.value = new_value
  self.signal_out:inform(new_value)
end

function NumberFrame:serialize()
  return ([[NumberFrame {
    value = %s;
  }]]):format(tostring(self.value))
end

function NumberFrame.id()
  return "Number"
end

return NumberFrame
