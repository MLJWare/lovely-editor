local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberPacket            = require "packet.Number"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local integer_filter          = require "input.filter.integer"
local InputFrame              = require "frame.Input"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"
local try_invoke              = pleasure.try.invoke

local IntegerFrame = {}
IntegerFrame.__index = IntegerFrame

IntegerFrame._kind = ";IntegerFrame;InputFrame;Frame;"

setmetatable(IntegerFrame, {
  __index = InputFrame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "IntegerFrame constructor must be a table.")

    if not frame.size then frame.size = vec2(64, 20) end
    IntegerFrame.typecheck(frame, "IntegerFrame constructor")

    frame.filter = integer_filter
    if not frame.value then
      frame.value = NumberPacket{ value = 0 }
    end

    frame.value.value = math.floor(frame.value.value)

    setmetatable(InputFrame(frame), IntegerFrame)
    frame._edit.hint_color = frame._edit.text_color
    frame._edit.hint = "0"

    return frame
  end;
})

function IntegerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberPacket.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be a NumberPacket.", where)
end

function IntegerFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";IntegerFrame;")
end

IntegerFrame.gives = IOs{
  {id = "value", kind = NumberPacket};
}

IntegerFrame.takes = IOs{
  {id = "value", kind = NumberPacket};
}

function IntegerFrame:on_connect(prop, from)
  if prop == "value" then
    self.value_in = from
    from:listen(self, self.refresh)
    self:refresh()
  end
end

function IntegerFrame:on_disconnect(prop)
  if prop == "value" then
    try_invoke(self.value_in, "unlisten", self, self.refresh)
    self.value_in = nil
  end
end

function IntegerFrame:locked()
  return self.value_in ~= nil
end

function IntegerFrame:draw(size, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)
  if self:locked() then
    local text = tostring(self.value.value)
    local x_pad = self._edit.x_pad*scale
    pleasure.push_region(x_pad, 0, size.x - 2*x_pad, size.y)
    pleasure.scale(scale)
    do
      local center_y = size.y/2/scale
      love.graphics.setColor(self._edit.text_color)
      font_writer.print_aligned(self._edit.font, text, 0, center_y, "left", "center")
    end
    pleasure.pop_region()
  else
    InputFrame.draw(self, size, scale)
  end
end

function IntegerFrame:refresh()
  local data = self.value
  local data_in = self.value_in
  if data_in then
    local new_value = math.floor(data_in.value)
    if data.value == new_value then return end
    data.value = new_value
    data:inform()
  else
    data.value = math.floor(tonumber(self._edit.text) or 0)
    data:inform()
  end
end

function IntegerFrame.id()
  return "Integer"
end

return IntegerFrame
