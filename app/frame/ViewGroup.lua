--local ViewGroup = require "ViewGroup"
local Frame                   = require "Frame"
local assertf                 = require "assertf"
local Project                 = require "app.Project"
local Viewport                = require "app.Viewport"
local is                      = require "pleasure.is"

local is_opt = is.opt
local is_table = is.table
local is_metakind = is.metakind

local ViewGroupFrame = {}
ViewGroupFrame.__index = ViewGroupFrame
ViewGroupFrame._kind = ";ViewGroupFrame;Frame;"

setmetatable(ViewGroupFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "ViewGroupFrame constructor must be a table.")
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
  assertf(is_opt(obj.project, Project.is), "Error in %s: Missing/invalid property: 'project' must be a Project.", where)
end

function ViewGroupFrame.is(obj)
  return is_metakind(obj, ";ViewGroupFrame;")
end

function ViewGroupFrame:draw(size_x, size_y, scale)

end

function ViewGroupFrame.serialize()
  require ("app").show_popup(require "frame.Message" { text = "Cannot save projects containing ViewGroupFrames (yet)" })
end

function ViewGroupFrame.id()
  return " Group"
end

return ViewGroupFrame
