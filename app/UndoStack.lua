local UndoStack = {}
UndoStack.__index = UndoStack

setmetatable(UndoStack, {
  __call = function (_)
    local self = setmetatable({
      _index = 1;
      _data  = {};
    }, UndoStack)
    return self
  end;
})

--- commits a new action to the stack, clearing all available redo's
function UndoStack:commit(action)
  if not action then
    print("Attempt to push nil action to UndoStack")
    return
  end
  local data  = self._data

  data[self._index] = action
  self._index = self._index + 1

  for i = #data, self._index, -1 do
    table.remove(data, i)
  end
end

--- undoes the last committed action
function UndoStack:undo(...)
  if self._index <= 1 then return end
  self._index = self._index - 1
  local action = self._data[self._index]
  return action:undo(...)
end

--- redoes the last undone action
function UndoStack:redo(...)
  local data = self._data
  if self._index > #data then return end
  local action = self._data[self._index]
  self._index = self._index + 1
  return action:redo(...)
end

return UndoStack