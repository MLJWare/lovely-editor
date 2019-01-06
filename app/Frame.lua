local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local try_invoke              = require "pleasure.try".invoke

local Frame = {}
Frame.__index = Frame

Frame._kind = ";Frame;"

setmetatable(Frame, {
  __call = function (_, frame)
    assert(type(frame) == "table", "Frame constructor must be a table.")
    Frame.typecheck(frame, "Frame constructor")
    setmetatable(frame, Frame)
    return frame
  end;
})

function Frame.typecheck(obj, where)
  assertf(vec2.is (obj.size), "Error in %s: Missing/invalid property: 'size' must be a Vector2.", where)
end

function Frame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";Frame;")
end

function Frame:id()
  return tostring(self):match("([^%s]*)$")
end

function Frame:clone()
  return Frame{
    size = self.size;
  }
end

function Frame:takes_count()
  local takes = self.takes
  return type(takes) == "table" and #takes or 0
end

function Frame:take_by_index(index)
  local takes = self.takes
  if type(takes) ~= "table" then return end
  local take = takes[index]
  if not take then return end
  return take.id, take.kind
end

function Frame:take_by_id(id)
  local takes = self.takes
  if type(takes) ~= "table" then return end
  for index = 1, #takes do
    local take = takes[index]
    if take.id == id then
      return index, take.kind
    end
  end
end

function Frame:request_focus()
  local focus_handler = self._focus_handler
  if not focus_handler then return false end
  return select(2, try_invoke(focus_handler, "request_focus", self))
end

function Frame:has_focus()
  local focus_handler = self._focus_handler
  if not focus_handler then return false end
  return select(2, try_invoke(focus_handler, "has_focus", self))
end

function Frame.refresh() end
function Frame.check_action() end

return Frame
