--local ViewGroup = require "ViewGroup"
local Frame = require "Frame"
local assertf = require "assertf"

local ViewGroupFrame = {}
ViewGroupFrame.__index = ViewGroupFrame

ViewGroupFrame._kind = ";ViewGroupFrame;Frame;"

setmetatable(ViewGroupFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ViewGroupFrame constructor must be a table.")
    ViewGroupFrame.typecheck(frame, "ViewGroupFrame constructor")

    setmetatable(frame, ViewGroupFrame)
    return frame
  end;
})

function ViewGroupFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(ViewGroup.is(obj.views), "Error in %s: Missing/invalid property: 'views' must be a ViewGroup.", where)
end

function ViewGroupFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ViewGroupFrame;")
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
function ViewGroupFrame:draw(size_x, _, scale)
  local font = fonts[math.max(1, math.min(#fonts, math.ceil(scale)))]
  scale = scale/(font[1]/16)
  text:setFont(font[2])
  text:setf(data, size_x/scale, "left", 10, 10)
  love.graphics.draw(text, 0, 0, 0, scale, scale)
  if math.random() < 0.01 then
    data[3], data[4], data[7], data[8] = data[7], data[8], data[3], data[4]
  end
end

function ViewGroupFrame.serialize()
  require "app".show_popup(require "frame.Message" { text = "Cannot save projects containing ViewGroupFrames (yet)" })
end

return ViewGroupFrame
