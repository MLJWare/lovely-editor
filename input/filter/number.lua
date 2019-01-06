return function (input)
  return input:gsub("([^0-9.]+)", ""):match("(%d*%.?%d*)")
end
