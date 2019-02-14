local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local number_filter           = require "input.filter.number"
local InputFrame              = require "frame.Input"
local pleasure                = require "pleasure"
local unpack_color            = require "util.color.unpack"
local font_writer             = require "util.font_writer"
local try_invoke              = pleasure.try.invoke

local NumberFrame = {}
NumberFrame.__index = NumberFrame

NumberFrame._kind = ";NumberFrame;InputFrame;Frame;"

setmetatable(NumberFrame, {
  __index = InputFrame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "NumberFrame constructor must be a table.")

    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or 20
    NumberFrame.typecheck(frame, "NumberFrame constructor")

    frame.signal_out = Signal {
      kind  = NumberKind;
      on_connect = function ()
        return frame.value;
      end;
    }

    frame.filter = number_filter
    frame.value = frame.value or 0

    setmetatable(InputFrame(frame), NumberFrame)

    frame._edit.hint_color = frame._edit.text_color
    frame._edit.hint = "0"
    frame._edit.text = tostring(frame.value)

    return frame
  end;
})

function NumberFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberKind.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be a number.", where)
end

function NumberFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";NumberFrame;")
end

NumberFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

NumberFrame.takes = IOs{
  {id = "signal_in", kind = NumberKind};
}

function NumberFrame:on_connect(prop, from, data)
  if prop == "signal_in" then
    self.signal_in = from
    from:listen(self, prop, self.refresh)
    self:refresh(prop, data)
  end
end

function NumberFrame:on_disconnect(prop)
  if prop == "signal_in" then
    try_invoke(self.signal_in, "unlisten", self, prop, self.refresh)
    self.signal_in = nil
  end
end

function NumberFrame:locked()
  return self.signal_in ~= nil
end

function NumberFrame:draw(size_x, size_y, scale)
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
