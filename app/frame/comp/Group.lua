local clamp                   = require "math.clamp"
local assertf                 = require "assertf"

local Group = {}
Group.__index = Group

Group._kind = ";Group;"

setmetatable(Group, {
  __call = function (_, group)
    assert(type(group) == "table", "Group constructor must be a table.")
    if not group._data then
      group._data = {}
    end
    Group.typecheck(group, "Group constructor")
    setmetatable(group, Group)
    return group
  end;
})

function Group.typecheck(obj, where)
  local data = obj._data
  assertf(type(data) == "table", "Error in %s: Missing/invalid property: '_data must be a table of strings.", where)
  for i = 1, #data do
    assertf(type(data[i]) == "string", "Error in %s: Missing/invalid property: '_data must be a table of strings.", where)
  end
end

function Group.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";Group;")
end

function Group:insert_row(condition, value, row_index)
  local data = self._data
  local index
  if not row_index then
    index = #data
  else
    index = clamp(2*(row_index - 1), 0, #data)
  end
  table.insert(data, index + 1, tostring(condition or "") or "")
  table.insert(data, index + 2, tostring(value or "") or "")
  return self
end

function Group:get_row(row_index)
  local data = self._data
  local index = clamp(2*(row_index - 1), 0, #data)
  return data[index + 1] or "", data[index + 2] or ""
end

function Group:set_row(row_index, condition, value)
  local data = self._data
  local index = clamp(2*(row_index - 1), 0, #data)
  data[index + 1] = tostring(condition or "") or ""
  data[index + 2] = tostring(value or "") or ""
end

function Group:get_condition(row_index)
  local data = self._data
  local index = clamp(2*(row_index - 1), 0, #data)
  return data[index + 1] or ""
end

function Group:set_condition(row_index, condition)
  local data = self._data
  local index = clamp(2*(row_index - 1), 0, #data)
  data[index + 1] = tostring(condition or "") or ""
end

function Group:get_value(row_index)
  local data = self._data
  local index = clamp(2*(row_index - 1), 0, #data)
  return data[index + 2] or ""
end

function Group:set_value(row_index, condition)
  local data = self._data
  local index = clamp(2*(row_index - 1), 0, #data)
  data[index + 2] = tostring(condition or "") or ""
end

function Group:get_direct(index)
  local data = self._data
  return data[index] or ""
end

function Group:set_direct(index, value)
  local data = self._data
  data[clamp(index, 1, #data)] = tostring(value or "") or ""
end

function Group:len()
  return math.ceil(#self._data / 2)
end

function Group:rows(from, to)
  return coroutine.wrap(function ()
    local data = self._data
    local len = self:len()
    from = math.max(from or 1, 1)
    to   = math.min(to or len, len)

    for row_index = from, to do
      local index = 2*(row_index - 1)
      coroutine.yield(data[index + 1] or "", data[index + 2] or "", row_index)
    end
  end)
end

function Group:dump()
  local result = {"{\n"}
  for condition, value in self:rows() do
    table.insert(result, ("  %q, %q;\n"):format(condition or "", value or ""))
  end
  table.insert(result, "}")
  return table.concat(result)
end

return Group
