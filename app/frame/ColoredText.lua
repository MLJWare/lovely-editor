--local ColoredText = require "ColoredText"
local Frame = require "Frame"
--local assertf = require "assertf"

local ColoredTextFrame = {}
ColoredTextFrame.__index = ColoredTextFrame

ColoredTextFrame._kind = ";ColoredTextFrame;Frame;"

setmetatable(ColoredTextFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ColoredTextFrame constructor must be a table.")
    ColoredTextFrame.typecheck(frame, "ColoredTextFrame constructor")

    setmetatable(frame, ColoredTextFrame)
    return frame
  end;
})

function ColoredTextFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(ColoredText.is(obj.views), "Error in %s: Missing/invalid property: 'views' must be a ColoredText.", where)
end

function ColoredTextFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ColoredTextFrame;")
end

local fonts = {
  { 16, love.graphics.newFont( 16)};
  { 32, love.graphics.newFont( 32)};
  { 48, love.graphics.newFont( 48)};
  { 64, love.graphics.newFont( 64)};
  { 80, love.graphics.newFont( 80)};
  {128, love.graphics.newFont(128)};
}

local text = love.graphics.newText(fonts[1][2], "")
local data = {
  {1, 0, 0, 1}, "local";
  {1, 0, 1, 1}, " test";
  {0, 1, 1, 1}, " = ";
  {1, 1, 0, 1}, " 100";
}
function ColoredTextFrame.draw(_, size_x, _, scale)
  local font = fonts[math.max(1, math.min(#fonts, math.ceil(scale)))]
  scale = scale/(font[1]/16)
  text:setFont(font[2])
  text:setf(data, size_x/scale, "left", 10, 10)
  love.graphics.draw(text, 0, 0, 0, scale, scale)
  if math.random() < 0.01 then
    data[3], data[4], data[7], data[8] = data[7], data[8], data[3], data[4]
  end
end

function ColoredTextFrame.serialize()
  require ("app").show_popup(require "frame.Message" { text = "Cannot save projects containing ColoredTextFrames (yet)" })
end

return ColoredTextFrame
