local TakeRef = {
  __call = function (ref, ...)
    local frame = ref._view.frame
    local take  = ref._take
    return frame.takes[take](frame, ...)
  end;
}

return function (view, take)
  return setmetatable({
    _view = view;
    _take = take;
  }, TakeRef)
end