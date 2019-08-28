return function (t1, t2)
  local result = {}
  local t1_len = #t1
  for i = 1, t1_len do
    result[i] = t1[i]
  end
  for i = 1, #t2 do
    result[i + t1_len] = t2[i]
  end
  return result
end

