local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"
local fontstore               = require "fontstore"

local font = fontstore.default[12]

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local DivideFrame = {}
DivideFrame.__index = DivideFrame
DivideFrame._kind = ";DivideFrame;Frame;"

setmetatable(DivideFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "DivideFrame constructor must be a table.")
    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or 20
    DivideFrame.typecheck(frame, "DivideFrame constructor")

    if not frame.value then
      frame.value = 0
    end
    frame.signal_out = Signal {
      kind = NumberKind;
      on_connect = function ()
        return frame.value;
      end;
    }

    setmetatable(Frame(frame), DivideFrame)
    return frame
  end;
})

function DivideFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(is_opt(obj.value, NumberKind.is), "Error in %s: Invalid optional property: 'value' must be a number.", where)
end

function DivideFrame.is(obj)
  return is_metakind(obj, ";DivideFrame;")
end

DivideFrame.takes = IOs{
  {id = "signal_left" , kind = NumberKind};
  {id = "signal_right", kind = NumberKind};
}


DivideFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

function DivideFrame:on_connect(prop, from, value)
  if prop == "signal_left" then
    self.signal_left = from
    from:listen(self, prop, self.refresh_left)
    self:refresh_left(prop, value)
  elseif prop == "signal_right" then
    self.signal_right = from
    from:listen(self, prop, self.refresh_right)
    self:refresh_right(prop, value)
  end
end

function DivideFrame:on_disconnect(prop)
  if prop == "signal_left" then
    self.signal_left:unlisten(self, prop, self.refresh_left)
    self.signal_left = nil
    self:refresh_left(prop, nil)
  elseif prop == "signal_right" then
    self.signal_right:unlisten(self, prop, self.refresh_right)
    self.signal_right = nil
    self:refresh_right(prop, nil)
  end
end

function DivideFrame:draw(size_x, size_y, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
  local text = tostring(self.value)
  pleasure.push_region(0, 0, size_x, size_y)
  pleasure.scale(scale)
  do
    local center_y = size_y/2/scale
    love.graphics.setColor(0.0, 0.0, 0.0)
    font_writer.print_aligned(font, text, 0, center_y, "left", "center")
  end
  pleasure.pop_region()
end

local function _num(v)
  return v and tonumber(v) or 0
end

function DivideFrame:refresh_left(_, value)
  self.value_left = value
  local val = _num(value) / _num(self.value_right)
  if val ~= val then val = 0 end -- replace NaN with 0
  self.value = val
  self.signal_out:inform(val)
end

function DivideFrame:refresh_right(_, value)
  self.value_right = value
  local val = _num(self.value_left) / _num(value)
  if val ~= val then val = 0 end -- replace NaN with 0
  self.value = val
  self.signal_out:inform(val)
end

function DivideFrame.serialize()
  return "DivideFrame {}"
end

function DivideFrame.id()
  return "Divide"
end

return DivideFrame
