local vec2    = require "linear-algebra.Vector2"
local Frame   = require "Frame"
local assertf = require "assertf"

local View = {}
View.__index = View

View._kind = ";View;"

View.frame = setmetatable({}, {
  __index = {size = vec2(8)};
})

setmetatable(View, {
  __call = function (_, view)
    assert(type(view) == "table", "View constructor must be a table.")
    View.typecheck(view, "View constructor")

    view.scale = view.scale or 1
    setmetatable(view, View)
    view.frame._view_ = view

    return view
  end;
})

function View.typecheck(obj, where)
  assertf(vec2.is(obj.pos ), "Error in %s: Missing/invalid property: 'pos' must be a Vector2.", where)
  assertf(not obj.scale or type(obj.scale) == "number", "Error in %s: Invalid optional property: 'scale' must be of a number.", where)
  assertf(not obj.frame or Frame.is(obj.frame), "Error in %s: invalid optional property: 'frame' must be a Frame.", where)
end

function View.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";View;")
end

function View:_serialize(frame2index, frames)
  local frame = self.frame
  local frame_index = frame2index[frame]
  if not frame_index then
    frame_index = 1 + #frames
    frame2index[frame] = frame_index
    frames[frame_index] = frame:serialize()
  end
  return ([[View {
    pos   = %s;
    scale = %s;
    frame = frames[%d];
  }]]):format(self.pos:serialize(), self.scale, frame_index)
end

return View
