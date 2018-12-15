return function (fn, list, accum)
  for i = 1, #list do
    accum = math.max(fn(list[i]), accum)
  end
  return accum
end