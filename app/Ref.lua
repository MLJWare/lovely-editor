local Ref = {
  __call = function (ref)
    local view = rawget(ref, "____view____")
    local prop = rawget(ref, "____prop____")
    local it   = view.frame[prop]
    return it
  end;
  __index = function (ref, k)
    local view = rawget(ref, "____view____")
    local prop = rawget(ref, "____prop____")
    local it   = view.frame[prop]
    return it[k]
  end;
}

return function (view, prop)
  return setmetatable({
    ____view____ = view;
    ____prop____ = prop;
  }, Ref)
end