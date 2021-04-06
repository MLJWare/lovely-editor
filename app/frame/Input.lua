local Frame                   = require "Frame"
local IOs                     = require "IOs"
local Signal                  = require "Signal"
local pleasure                = require "pleasure"
local EditableText            = require "EditableText"
local StringKind              = require "Kind.String"
local unpack_color            = require "util.color.unpack"
local font_writer             = require "util.font_writer"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class InputFrame : Frame
---@field hint string hint text shown when no text has been inputted
---@field signal_out Signal output signal
---@field value any
---@field _edit EditableText
local InputFrame = {}
InputFrame.__index = InputFrame
InputFrame._kind = ";InputFrame;Frame;"

setmetatable(InputFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "InputFrame constructor must be a table.")

    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or 20
    InputFrame.typecheck(frame, "InputFrame constructor")

    frame._edit = EditableText{
      text   = "";
      hint   = "";
      size_x = frame.size_x;
      size_y = frame.size_y;
    }
    frame._edit.hint_color = frame._edit.text_color

    frame.signal_out = Signal {
      kind  = StringKind;
      on_connect = function ()
        return frame.value;
      end;
    }

    setmetatable(frame, InputFrame)
    return frame
  end;
})

InputFrame.typecheck = Frame.typecheck

function InputFrame.is(obj)
  return is_metakind(obj, ";InputFrame;")
end

InputFrame.gives = IOs{
  {id = "signal_out", kind = StringKind};
}

InputFrame.takes = IOs{
  {id = "signal_in", kind = StringKind};
}

function InputFrame:on_connect(prop, from, data)
  if prop == "signal_in" then
    self.signal_in = from
    from:listen(self, prop, self.refresh)
    self:refresh(prop, data)
  end
end

function InputFrame:on_disconnect(prop)
  if prop == "signal_in" then
    try_invoke(self.signal_in, "unlisten", self, prop, self.refresh)
    self.signal_in = nil
  end
end

function InputFrame:draw(size_x, size_y, scale)
  if self:locked() then
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.rectangle("fill", 0, 0, size_x, size_y)
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
    pleasure.push_region()
    self._edit:draw(self, scale)
    pleasure.pop_region()
  end
end

function InputFrame:mousepressed(mx, my, button)
  if self:locked() then return end
  self:request_focus()
  self._edit:mousepressed(mx, my, button)
end

function InputFrame:mousedragged1(mx, my)
  if self:locked() then return end
  self._edit:mousedragged1(mx, my)
end

function InputFrame:keypressed(key, scancode, isrepeat)
  if self:locked() then return end
  if key == "return" then
    self:refresh()
  else
    self._edit:keypressed(key, scancode, isrepeat)
  end
end

function InputFrame:locked()
  return self.signal_in ~= nil
end

function InputFrame:textinput(text)
  self._edit:textinput(text)
end

function InputFrame:focusgained()
  self._edit.focused = true
end

function InputFrame:focuslost()
  self._edit.focused = false
  if not self:locked() then
    self:refresh()
  end
end

return InputFrame
