return function (line, index, count)
  count = math.max(0, count or 1)
  return line:sub(1, math.max(0, index - 1)), line:sub(index, index + count - 1), line:sub(index + count)
end
