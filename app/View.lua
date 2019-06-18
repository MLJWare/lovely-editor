local Frame   = require "Frame"
local assertf = require "assertf"
local is = require "pleasure.is"

local is_opt = is.opt
local is_table = is.table
local is_number = is.number
local is_metakind = is.metakind

local View = {}
View.__index = View
View._kind = ";View;"

View.frame = setmetatable({}, {
  __index = {
    size_x = 8;
    size_y = 8;
  };
})

setmetatable(View, {
  __call = function (_, view)
    assert(is_table(view), "View constructor must be a table.")
    View.typecheck(view, "View constructor")

    view.scale = view.scale or 1
    setmetatable(view, View)
    view.frame._view_ = view

    return view
  end;
})

function View.typecheck(obj, where)
  assertf(is_number(obj.pos_x), "Error in %s: Missing/invalid property: 'pos_x' must be a number.", where)
  assertf(is_number(obj.pos_y), "Error in %s: Missing/invalid property: 'pos_y' must be a number.", where)
  assertf(is_opt(obj.scale, is_number), "Error in %s: Invalid optional property: 'scale' must be of a number.", where)
  assertf(is_opt(obj.frame, Frame.is), "Error in %s: invalid optional property: 'frame' must be a Frame.", where)
end

function View.is(obj)
  return is_metakind(obj, ";View;")
end

function View:id()
  return self._id or (" %s"):format(self.frame:id())
end

function View:_serialize(frame2index, frames)
  local frame = self.frame
  local frame_index = frame2index[frame]
  if not frame_index then
    frame_index = 1 + #frames
    frame2index[frame] = frame_index
    frames[frame_index] = frame:serialize()
  end
  local id = self._id
  if id then
    return ([[View {
    _id   = %q;
    pos_x = %s;
    pos_y = %s;
    scale = %s;
    frame = frames[%d];
  }]]):format(self._id, self.pos_x, self.pos_y, self.scale, frame_index)
  else
    return ([[View {
    pos_x = %s;
    pos_y = %s;
    scale = %s;
    frame = frames[%d];
  }]]):format(self.pos_x, self.pos_y, self.scale, frame_index)
  end
end

return View
