return function (fn, accum, list)
  for i = 1, #list do
    fn(list[i], accum)
  end
  return accum
end
