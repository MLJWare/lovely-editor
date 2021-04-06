local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table

---@class FocusHandler
local FocusHandler = {}
FocusHandler.__index = FocusHandler

setmetatable(FocusHandler, {
  __call = function (_)
    local self = setmetatable({}, FocusHandler)
    return self
  end;
})

function FocusHandler:assign(item)
  item._focus_handler = self
end

function FocusHandler:unassign(item)
  if not item then return end
  item._focus_handler = nil
  if self._has_focus == item then
    self._has_focus = nil
  end
end

function FocusHandler:ensure_unfocused(item)
    if not item then return end
    if self._has_focus == item then
        self._has_focus = nil
    end
end

function FocusHandler:request_focus(item)
  if item ~= self._has_focus then
    local has_focus = self._has_focus
    if has_focus then
      try_invoke(has_focus, "focuslost")
      self._has_focus = nil
    end
    if is_table(item) then
      self._has_focus = item
      try_invoke(item, "focusgained")
      return true
    end
  end
  return false
end

function FocusHandler:has_focus(item)
  if item then
    return item == self._has_focus
  end
  return self._has_focus
end

return FocusHandler
