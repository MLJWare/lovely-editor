local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local integer_filter          = require "input.filter.integer"
local InputFrame              = require "frame.Input"
local pleasure                = require "pleasure"
local unpack_color            = require "util.color.unpack"
local font_writer             = require "util.font_writer"

local try_invoke = pleasure.try.invoke

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local IntegerFrame = {}
IntegerFrame.__index = IntegerFrame
IntegerFrame._kind = ";IntegerFrame;InputFrame;Frame;"

setmetatable(IntegerFrame, {
  __index = InputFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "IntegerFrame constructor must be a table.")
    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or 20
    IntegerFrame.typecheck(frame, "IntegerFrame constructor")

    frame.signal_out = Signal {
      kind  = NumberKind;
      on_connect = function ()
        return frame.value;
      end;
    }
    frame.filter = integer_filter
    frame.value = math.floor(frame.value or 0)

    setmetatable(InputFrame(frame), IntegerFrame)

    frame._edit.hint_color = frame._edit.text_color
    frame._edit.hint = "0"
    frame._edit.text = tostring(frame.value)

    return frame
  end;
})

function IntegerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(is_opt(obj.value, NumberKind.is), "Error in %s: Invalid optional property: 'value' must be a number.", where)
end

function IntegerFrame.is(obj)
  return is_metakind(obj, ";IntegerFrame;")
end

IntegerFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

IntegerFrame.takes = IOs{
  {id = "signal_in", kind = NumberKind};
}

function IntegerFrame:on_connect(prop, from, data)
  if prop == "signal_in" then
    self.signal_in = from
    from:listen(self, prop, self.refresh)
    self:refresh(prop, data)
  end
end

function IntegerFrame:on_disconnect(prop)
  if prop == "signal_in" then
    try_invoke(self.signal_in, "unlisten", self, prop, self.refresh)
    self.signal_in = nil
  end
end

function IntegerFrame:locked()
  return self.signal_in ~= nil
end

function IntegerFrame:draw(size_x, size_y, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
  if self:locked() then
    local text = tostring(self.value)
    local x_pad = self._edit.x_pad*scale
    pleasure.push_region(x_pad, 0, size_x - 2*x_pad, size_y)
    pleasure.scale(scale)
    do
      local center_y = size_y/2/scale
      love.graphics.setColor(unpack_color(self._edit.text_color))
      font_writer.print_aligned(self._edit.font, text, 0, center_y, "left", "center")
    end
    pleasure.pop_region()
  else
    InputFrame.draw(self, size_x, size_y, scale)
  end
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
