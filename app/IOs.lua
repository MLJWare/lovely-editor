local IOs = {}

return setmetatable(IOs, {
  __call = function (_, t)
    for i, v in ipairs(t) do
      t[v] = i
    end
    return setmetatable(t, IOs)
  end;
})