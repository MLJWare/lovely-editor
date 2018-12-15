local GiveRef = {
  __index = function (ref, k)
    local view = rawget(ref, "____ref_view____")
    local give = rawget(ref, "____ref_give____")
    local it   = view.frame[give]
    return it[k]
  end;
}

return function (view, prop)
  return setmetatable({
    ____ref_view____ = view;
    ____ref_prop____ = prop;
  }, GiveRef)
end