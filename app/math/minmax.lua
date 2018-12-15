return function (a, b)
  if a < b then
    return a, b
  end
  return b, a
end