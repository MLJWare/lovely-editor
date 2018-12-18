return function (line, pos, count)
  count = math.max(0, count or 1)
  return line:sub(1, math.max(0, pos - 1)), line:sub(pos, pos + count - 1), line:sub(pos + count)
end
