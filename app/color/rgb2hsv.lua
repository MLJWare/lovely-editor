return function (red, green, blue)
  local cmin  = math.min(red, green, blue)
  local cmax  = math.max(red, green, blue)
  local delta = cmax - cmin

  local hue = (delta == 0    ) and 0
           or (cmax  == red  ) and (green - blue)/delta % 6
           or (cmax  == green) and (blue - red)/delta + 2
           or --[[cmax == blue]]   (red - green)/delta + 4
  local saturation = (cmax ~= 0) and delta/cmax or 0
  local value = cmax

  return hue, saturation, value
end
