return function (hue, sat, val)
  hue = hue % 6
  sat = sat < 0 and 0 or sat > 1 and 1 or sat
  val = val < 0 and 0 or val > 1 and 1 or val

  local intensity  = sat * val
  local amount     = (1-math.abs((hue%2)-1))*intensity

  local r, g, b
      if hue < 1 then r,g,b = intensity, amount, 0
  elseif hue < 2 then r,g,b = amount, intensity, 0
  elseif hue < 3 then r,g,b = 0, intensity, amount
  elseif hue < 4 then r,g,b = 0, amount, intensity
  elseif hue < 5 then r,g,b = amount, 0, intensity
  else                r,g,b = intensity, 0, amount
  end

  local mid = val - intensity

  return r+mid, g+mid, b+mid
end
