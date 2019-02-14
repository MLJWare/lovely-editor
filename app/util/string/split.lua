return function (line, index)
  return line:sub(1, math.max(0, index - 1)), line:sub(index)
end
