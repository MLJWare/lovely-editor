local Frame                   = require "Frame"
local vec2                    = require "linear-algebra.Vector2"
local pleasure                = require "pleasure"
local EditableText            = require "EditableText"

local InputFrame = {}
InputFrame.__index = InputFrame

InputFrame._kind = ";InputFrame;Frame;"

setmetatable(InputFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "InputFrame constructor must be a table.")

    if not frame.size then
      frame.size = vec2(64, 20)
    end

    InputFrame.typecheck(frame, "InputFrame constructor")

    frame._edit = EditableText{
      text   = "";
      filter = frame.filter;
      size   = frame.size;
      hint   = frame.hint or "";
    }

    setmetatable(frame, InputFrame)
    return frame
  end;
})

function InputFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(type(obj.value) == "number", "Error in %s: Missing/invalid property: 'value' must be a number.", where)
end

function InputFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";InputFrame;")
end

function InputFrame:draw(_, scale)
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