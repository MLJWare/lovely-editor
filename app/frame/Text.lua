local IOs                     = require "IOs"
local Frame                   = require "Frame"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"


local TextFrame = {}
TextFrame.__index = TextFrame

TextFrame._kind = ";TextFrame;Frame;"

setmetatable(TextFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "TextFrame constructor must be a table.")
    TextFrame.typecheck(frame, "TextFrame constructor")
    setmetatable(frame, TextFrame)
    return frame
  end;
})

local monofont = love.graphics.newFont("res/font/Cousine-Regular.ttf", 12)

function TextFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(type(obj.text) == "string", "Error in %s: Missing/invalid property: 'text' must be a string.", where)
end

function TextFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";TextFrame;")
end

TextFrame.gives = IOs{
  {id = "text", kind = string};
}

function TextFrame:draw(size)
  local old_font = love.graphics.getFont()
  love.graphics.setFont(monofont)
  pleasure.push_region(0, 0, size.x, size.y)
  do
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, size.x, size.y)
    love.graphics.setColor(1, 1, 1)

    love.graphics.print(self.text)
  end
  pleasure.pop_region()
  love.graphics.setFont(old_font)
end

return TextFrame