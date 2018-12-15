return function (t, k)
  assert(t and k)
  local tk = t[k]
  if not tk then
    tk = {}
    t[k] = tk
  end
  return tk
end