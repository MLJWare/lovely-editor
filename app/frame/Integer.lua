local Frame                   = require "Frame"
local IOs                     = require "IOs"
local Integer                 = require "packet.Integer"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local integer_filter          = require "input.filter.integer"
local InputFrame              = require "frame.Input"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"

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
      frame.value = Integer{ value = 0 }
    end

    frame._own_value = frame.value

    setmetatable(InputFrame(frame), IntegerFrame)
    frame._edit.hint_color = frame._edit.text_color
    frame._edit.hint = "0"

    return frame
  end;
})

function IntegerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or Integer.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be an Integer.", where)
end

function IntegerFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";IntegerFrame;")
end

IntegerFrame.gives = IOs{
  {id = "value", kind = Integer};
}

IntegerFrame.takes = IOs{
  {id = "value", kind = Integer};
}

function IntegerFrame:on_connect(prop, from)
  if prop == "value" then
    self.value = from
    from:listen(self, self.refresh)
    self:refresh()
  end
end

function IntegerFrame:on_disconnect(prop)
  if prop == "value" then
    self.value:unlisten(self)
    self.value = self._own_value
  end
end

function IntegerFrame:locked()
  return self.value ~= self._own_value
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
  if self:locked() then return end
  self.value.value = tonumber(self._edit.text) or 0
  self.value:inform()
end

function IntegerFrame.id()
  return "Integer"
end

return IntegerFrame