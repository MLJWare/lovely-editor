local function _clone(data)
  if type(data) == "userdata" then
    if type(data.clone) == "function" then
      return data:clone()
    else
      local data_type = type(data.type) == "function" and data:type() or "userdata"
      error(("Cannot clone %q"):format(data_type))
    end
  elseif type(data) ~= "table" then
    return data
  end

  local _meta = getmetatable(data)
  if type(_meta) == "table" and _meta.__immutable then
     --don't clone 'immutable' tables
    return data
  elseif type(data.clone) == "function" then
    return data:clone()
  end

  -- deep cloning of 'mutable' tables
  local new = {}
  for k, v in pairs(data) do
    new[k] = _clone(v)
  end
  return setmetatable(new, _meta)
end

return _clone
