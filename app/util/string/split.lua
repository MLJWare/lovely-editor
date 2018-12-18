return function (line, pos)
  return line:sub(1, math.max(0, pos - 1)), line:sub(pos)
end
