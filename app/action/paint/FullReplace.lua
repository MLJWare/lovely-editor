local Action = {}
Action.__index = Action

function Action:undo(data)
  data:paste(self._old, 0, 0)
end

function Action:redo(data)
  data:paste(self._new, 0, 0)
end

function Action.apply(data, old_data)
  return setmetatable({
    _old  = old_data;
    _new  = data:clone();
  }, Action)
end

return Action
