local NewSizedViewFrame = require "frame.NewSizedView"
local PixelFrame = require "frame.Pixel"
local pleasure = require "pleasure"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class NewPixelViewFrame : NewSizedViewFrame
local NewPixelViewFrame = {
  title = "New Pixel View"
}
NewPixelViewFrame.__index = NewPixelViewFrame
NewPixelViewFrame._kind = ";NewPixelViewFrame;Frame;"

setmetatable(NewPixelViewFrame, {
  __index = NewSizedViewFrame;
  __call  = function (_, frame)
    assert(is_table(frame), "NewPixelViewFrame constructor must be a table.")
    frame = NewSizedViewFrame(frame)
    setmetatable(frame, NewPixelViewFrame)
    return frame
  end;
})

function NewPixelViewFrame.create_new_frame(_, width, height)
  return PixelFrame {
    data = love.image.newImageData(width, height);
  };
end

function NewPixelViewFrame.is(obj)
  return is_metakind(obj, ";NewPixelViewFrame;")
end

return NewPixelViewFrame
