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

function ViewGroupFrame:draw(size, scale)

end

return ViewGroupFrame
