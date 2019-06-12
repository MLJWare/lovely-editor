--local ViewGroup = require "ViewGroup"
local Frame = require "Frame"
local assertf = require "assertf"
local Project = require "app.Project"
local Viewport = require "app.Viewport"

local ViewGroupFrame = {}
ViewGroupFrame.__index = ViewGroupFrame

ViewGroupFrame._kind = ";ViewGroupFrame;Frame;"

setmetatable(ViewGroupFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ViewGroupFrame constructor must be a table.")
    ViewGroupFrame.typecheck(frame, "ViewGroupFrame constructor")

    frame.project = frame.project or Project {
      viewport = Viewport {
        pos_x  = 0;
        pos_y  = 0;
        scale  = 1;
      };
      views  = {};
      _links = {};
      show_connections = true;
    };


    setmetatable(frame, ViewGroupFrame)
    return frame
  end;
})

function ViewGroupFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.project or Project.is(obj.project), "Error in %s: Missing/invalid property: 'project' must be a Project.", where)
end

function ViewGroupFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ViewGroupFrame;")
end

function ViewGroupFrame:draw(size_x, size_y, scale)

end

function ViewGroupFrame.serialize()
  require ("app").show_popup(require "frame.Message" { text = "Cannot save projects containing ViewGroupFrames (yet)" })
end

return ViewGroupFrame
