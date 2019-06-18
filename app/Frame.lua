local assertf                 = require "assertf"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind
local is_non_negative = pleasure.is.non_negative_number

local Frame = {}
Frame.__index = Frame
Frame._kind = ";Frame;"

setmetatable(Frame, {
  __call = function (_, frame)
    assert(is_table(frame), "Frame constructor must be a table.")
    Frame.typecheck(frame, "Frame constructor")
    setmetatable(frame, Frame)
    return frame
  end;
})

function Frame.typecheck(obj, where)
  assertf(is_non_negative (obj.size_x), "Error in %s: Missing/invalid property: 'size_x' must be a non-negative number.", where)
  assertf(is_non_negative (obj.size_y), "Error in %s: Missing/invalid property: 'size_y' must be a non-negative number.", where)
end

function Frame.is(obj)
  return is_metakind(obj, ";Frame;")
end

function Frame:serialize()
  return ([[Frame {
    size_x = %s;
    size_y = %s;
  }]]):format(self.size_x, self.size_y)
end

function Frame:id()
  return tostring(self):match("([^%s]*)$")
end

function Frame:clone()
  return Frame{
    size_x = self.size_x;
    size_y = self.size_y;
  }
end

function Frame:_pos(mx, my)
  local display_size_x, display_size_y = love.graphics.getDimensions()

  local x = math.max(0, math.min(mx, display_size_x - self.size_x))
  local y = math.max(0, math.min(my, display_size_y - self.size_y))

  return x, y
end

function Frame:takes_count()
  local takes = self.takes
  return is_table(takes) and #takes or 0
end

function Frame:take_by_index(index)
  local takes = self.takes
  if not is_table(takes) then return end
  local take = takes[index]
  if not take then return end
  return take.id, take.kind
end

function Frame:take_by_id(id)
  local takes = self.takes
  if not is_table(takes) then return end
  for index = 1, #takes do
    local take = takes[index]
    if take.id == id then
      return index, take.kind
    end
  end
end

function Frame:gives_count()
  local gives = self.gives
  return is_table(gives) and #gives or 0
end

function Frame:give_by_index(index)
  local gives = self.gives
  if not is_table(gives) then return end
  local give = gives[index]
  if not give then return end
  return give.id, give.kind
end

function Frame:give_by_id(id)
  local gives = self.gives
  if not is_table(gives) then return end
  for index = 1, #gives do
    local give = gives[index]
    if give.id == id then
      return index, give.kind
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
