local pack_color              = require "util.color.pack"
local minmax                  = require "math.minmax"

local function _color_at(data, px, py)
  return pack_color(data:getPixel(px, py))
end

local function iter_none()
  return coroutine.wrap(function() end)
end

local function iter_point(x, y, width, height)
  if  0 <= x and x < width
  and 0 <= y and y < height then
    return coroutine.wrap(function ()
      coroutine.yield(1, x, y)
    end)
  else
    return iter_none()
  end
end

local function iter_hline(x1, x2, y, width, height)
  if  0 <= y and y < height then
    return coroutine.wrap(function ()
      local index = 1
      for x = math.max(0, math.min(x1, x2)), math.min(math.max(x1, x2), width - 1) do
        coroutine.yield(index, x, y); index = index + 1
      end
    end)
  else
    return iter_none()
  end
end

local function iter_vline(x, y1, y2, width, height)
  if  0 <= x and x < width then
    return coroutine.wrap(function ()
      local index = 1
      for y = math.max(0, math.min(y1, y2)), math.min(math.max(y1, y2), height - 1) do
        coroutine.yield(index, x, y); index = index + 1
      end
    end)
  else
    return iter_none()
  end
end

local function iter_rectangle(x1, y1, x2, y2, width, height)
  x1, x2 = math.floor(x1), math.floor(x2)
  y1, y2 = math.floor(y1), math.floor(y2)

  if x1 == x2 and y1 == y2 then
    return iter_point(x1, y1, width, height)
  elseif x1 == x2 then
    return iter_vline(x1, y1, y2, width, height)
  elseif y1 == y2 then
    return iter_hline(x1, x2, y1, width, height)
  else
    return coroutine.wrap(function ()
      local index = 1
      local x_min, x_max = minmax(x1, x2)
      local y_min, y_max = minmax(y1, y2)
      if 0 <= y1 and y1 < height then
        for x = math.max(0, x_min), math.min(x_max, width - 1) do
          coroutine.yield(index, x, y1); index = index + 1
        end
      end
      if 0 <= y2 and y2 < height then
        for x = math.max(0, x_min), math.min(x_max, width - 1) do
          coroutine.yield(index, x, y2); index = index + 1
        end
      end
      if 0 <= x1 and x1 < width then
        for y = math.max(0, y_min) + 1, math.min(y_max, height - 1) - 1 do
          coroutine.yield(index, x1, y); index = index + 1
        end
      end
      if 0 <= x2 and x2 < width then
        for y = math.max(0, y_min) + 1, math.min(y_max, height - 1) - 1 do
          coroutine.yield(index, x2, y); index = index + 1
        end
      end
    end)
  end
end

local function iter_line(x1, y1, x2, y2, width, height)
  return coroutine.wrap(function ()
    x1, x2 = math.floor(x1), math.floor(x2)
    y1, y2 = math.floor(y1), math.floor(y2)

    if x1 == x2 and y1 == y2 then
      if  0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(1, x1, y1)
      end
      return
    end

    local index = 2
    local dx, dy, ix, iy
    if x1 < x2 then dx, ix = x2 - x1,  1
    else dx, ix = x1 - x2, -1 end
    if y1 < y2 then dy, iy = y2 - y1,  1
    else dy, iy = y1 - y2, -1 end

    if dx > dy then
      local det, y = 2*dy - dx, y1
      for x = x1, x2, ix do
        if  0 <= x and x < width
        and 0 <= y and y < height then
          coroutine.yield(index, x, y); index = index + 1
        end
        if det > 0 then
          y = y + iy
          det = det - 2*dx
        end
        det = det + 2*dy
      end
    else
      local det, x = 2*dx - dy, x1
      for y = y1, y2, iy do
        if  0 <= x and x < width
        and 0 <= y and y < height then
          coroutine.yield(index, x, y); index = index + 1
        end
        if det > 0 then
          x = x + ix
          det = det - 2*dy
        end
        det = det + 2*dx
      end
    end
  end)
end

local function iter_circle(cx, cy, radius, width, height)
  return coroutine.wrap(function ()
    radius = math.floor(radius)
    cx = math.floor(cx*2)/2
    cy = math.floor(cy*2)/2

    if radius <= 0 then return end
    if radius <= 1 then
      coroutine.yield(1, cx, cy)
      return
    end

    local  x,  y   = radius, 0
    local dx, dy   = 1, 1
    local diameter = radius * 2
    local err      = dx - diameter

    local i1x, i1y = cx + x, cy
    local i2x, i2y = cx    , cy + x
    local i3x, i3y = cx    , cy + x
    local i4x, i4y = cx - x, cy
    local i5x, i5y = cx - x, cy
    local i6x, i6y = cx    , cy - x
    local i7x, i7y = cx    , cy - x
    local i8x, i8y = cx + x, cy

    local index = 1

    if  0 <= i1x and i1x < width
    and 0 <= i1y and i1y < height then
      coroutine.yield(index, i1x, i1y); index = index + 1
    end

    if  0 <= i3x and i3x < width
    and 0 <= i3y and i3y < height then
      coroutine.yield(index, i3x, i3y); index = index + 1
    end

    if  0 <= i5x and i5x < width
    and 0 <= i5y and i5y < height then
      coroutine.yield(index, i5x, i5y); index = index + 1
    end

    if  0 <= i7x and i7x < width
    and 0 <= i7y and i7y < height then
      coroutine.yield(index, i7x, i7y); index = index + 1
    end

    while x >= y do
      local x1, y1

      if x == y then
        -- first octant
        x1, y1 = cx + x, cy + x
        if  0 <= x1 and x1 < width
        and 0 <= y1 and y1 < height then
          coroutine.yield(index, x1, y1); index = index + 1
        end
        -- third octant
        x1, y1 = cx - x, cy + x
        if  0 <= x1 and x1 < width
        and 0 <= y1 and y1 < height then
          coroutine.yield(index, x1, y1); index = index + 1
        end
        -- fifth octant
        x1, y1 = cx - x, cy - x
        if  0 <= x1 and x1 < width
        and 0 <= y1 and y1 < height then
          coroutine.yield(index, x1, y1); index = index + 1
        end
        -- seventh octant
        x1, y1 = cx + x, cy - x
        if  0 <= x1 and x1 < width
        and 0 <= y1 and y1 < height then
          coroutine.yield(index, x1, y1)--; index = index + 1
        end
        return
      end

      -- first octant
      x1, y1 = cx + x, cy + y
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- second octant
      x1, y1 = cx + y, cy + x
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- third octant
      x1, y1 = cx - y, cy + x
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- fourth octant
      x1, y1 = cx - x, cy + y
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- fifth octant
      x1, y1 = cx - x, cy - y
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- sixth octant
      x1, y1 = cx - y, cy - x
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- seventh octant
      x1, y1 = cx + y, cy - x
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end
      -- eighth octant
      x1, y1 = cx + x, cy - y
      if  (x1 ~= i1x or y1 ~= i1y)
      and (x1 ~= i2x or y1 ~= i2y)
      and (x1 ~= i3x or y1 ~= i3y)
      and (x1 ~= i4x or y1 ~= i4y)
      and (x1 ~= i5x or y1 ~= i5y)
      and (x1 ~= i6x or y1 ~= i6y)
      and (x1 ~= i7x or y1 ~= i7y)
      and (x1 ~= i8x or y1 ~= i8y)
      and 0 <= x1 and x1 < width
      and 0 <= y1 and y1 < height then
        coroutine.yield(index, x1, y1); index = index + 1
      end

      if err <= 0 then
        y  = y + 1
        err  = err + dy
        dy = dy + 2
      end

      if err > 0 then
        x  = x - 1
        dx = dx + 2
        err  = err + dx - diameter
      end
    end
  end)
end

local function iter_fill(data, px1, py1, fill_color, override_color, width, height)
  return coroutine.wrap(function ()
    px1 = math.floor(px1)
    py1 = math.floor(py1)

    if not (0 <= px1 and px1 < width
        and 0 <= py1 and py1 < height) then return end

    if not override_color then
      override_color = _color_at(data, px1, py1)
    end

    if fill_color == override_color then return end

    local stack_x = { px1 }
    local stack_y = { py1 }

    local px_left, px_right

    while #stack_x > 0 do
      local px = table.remove( stack_x )
      local py = table.remove( stack_y )

      if _color_at(data, px, py) == override_color then
        px_left  = px
        px_right = px

        for x = px, 0, -1 do
          if _color_at(data, x, py) ~= override_color then break end
          px_left = x
        end
        for x = px, width - 1 do
          if _color_at(data, x, py) ~= override_color then break end
          px_right = x
        end

        local py_above = py - 1
        local py_below = py + 1

        local index = 1
        for px2 = px_left, px_right do
          coroutine.yield(index, px2, py); index = index + 1
          if py_above >= 0 and _color_at(data, px2, py_above) == override_color then
            table.insert(stack_x, px2)
            table.insert(stack_y, py_above)
          end
          if py_below < height and _color_at(data, px2, py_below) == override_color then
            table.insert(stack_x, px2)
            table.insert(stack_y, py_below)
          end
        end
      end
    end
  end)
end

return {
  line      = iter_line;
  fill      = iter_fill;
  circle    = iter_circle;
  rectangle = iter_rectangle;
}