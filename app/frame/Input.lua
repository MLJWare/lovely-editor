local Frame                   = require "Frame"
local pleasure                = require "pleasure"
local EditableText            = require "EditableText"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

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
      filter = frame.filter;
      size_x = frame.size_x;
      size_y = frame.size_y;
      hint   = frame.hint or "";
    }

    setmetatable(frame, InputFrame)
    return frame
  end;
})

function InputFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function InputFrame.is(obj)
  return is_metakind(obj, ";InputFrame;")
end

function InputFrame:draw(_, _, scale)
  pleasure.push_region()
  self._edit:draw(self, scale)
  pleasure.pop_region()
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
  return false
end

function InputFrame:textinput(text)
  self._edit:textinput(text)
end

function InputFrame:focusgained()
  self._edit.focused = true
end

function InputFrame:focuslost()
  self:refresh()
  self._edit.focused = false
end

return InputFrame
