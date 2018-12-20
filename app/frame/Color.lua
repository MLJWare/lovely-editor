local Color = require "color.Color"
local Frame = require "Frame"
local assertf = require "assertf"

local ColorFrame = {}
ColorFrame.__index = ColorFrame

ColorFrame._kind = ";ColorFrame;Frame;"

setmetatable(ColorFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ColorFrame constructor must be a table.")
    ColorFrame.typecheck(frame, "ColorFrame constructor")

    setmetatable(frame, ColorFrame)
    return frame
  end;
})

function ColorFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(Color.is(obj.color), "Error in %s: Missing/invalid property: 'color' must be a Color.", where)
end

function ColorFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ColorFrame;")
end

function ColorFrame:draw(size)
  love.graphics.setColor(self.color)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)
end

return ColorFrame