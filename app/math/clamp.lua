return function (val, min, max)
  return val < min and min or val > max and max or val
end
