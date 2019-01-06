local assertf = require "assertf"

local Color = {}
Color.__index = Color

Color._kind = ";Color;"

setmetatable(Color, {
  __call = function (_, color)
    assert(type(color) == "table", "Color constructor must be a table.")
    Color.typecheck(color, "Color table")
    if not color[4] then color[4] = 1 end
    setmetatable(color, Color)
    return color
  end;
})

function Color.hex(c)
  local bor, band, lshift = bit.bor, bit.band, bit.lshift
  return bor( lshift(band(c[1]*255, 0xFF), 24)
            , lshift(band(c[2]*255, 0xFF), 16)
            , lshift(band(c[3]*255, 0xFF),  8)
            ,        band(c[4]*255, 0xFF)    )
end

function Color.typecheck(obj, where)
  for i = 1, math.max(3, math.min(#obj, 4)) do
    assertf(type(obj[i]) == "number", "%s must contain 3-4 numbers.", where)
  end
end

function Color.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";Color;")
end

function Color.__eq(a, b)
  return a[1] == b[1]
     and a[2] == b[2]
     and a[3] == b[3]
     and a[4] == b[4]
end

return Color
