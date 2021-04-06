local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

---@class BaseMathFrame : Frame
---@field value_left number|nil
---@field value_right number|nil
---@field signal_out Signal
---@field value number
---@field _calculate_value function
local BaseMathFrame = {}
BaseMathFrame.__index = BaseMathFrame
BaseMathFrame._kind = ";BaseMathFrame;Frame;"

setmetatable(BaseMathFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "BaseMathFrame constructor must be a table.")
    frame.size_x = frame.size_x or 20
    frame.size_y = frame.size_y or 20
    BaseMathFrame.typecheck(frame, "BaseMathFrame constructor")

    frame.value = tonumber(frame.value) or 0
    frame.signal_out = Signal {
      kind = NumberKind;
      on_connect = function ()
        return frame.value;
      end;
    }

    setmetatable(Frame(frame), BaseMathFrame)
    return frame
  end;
})

function BaseMathFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(is_opt(obj.value, NumberKind.is), "Error in %s: Invalid optional property: 'value' must be a number.", where)
end

function BaseMathFrame.is(obj)
  return is_metakind(obj, ";BaseMathFrame;")
end

BaseMathFrame.takes = IOs{
  {id = "signal_left" , kind = NumberKind, hint = "left"};
  {id = "signal_right", kind = NumberKind, hint = "right"};
}

BaseMathFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind, hint = "value"};
}

---@param self BaseMathFrame
---@param value number|nil
local function refresh_left(self, _, value)
  self.value_left = value
  local val = self:_calculate_value(tonumber(value) or 0, tonumber(self.value_right) or 0)
  if val ~= val then val = 0 end -- replace NaN with 0
  self.value = val
  self.signal_out:inform(val)
end

---@param self BaseMathFrame
---@param value number|nil
local function refresh_right(self, _, value)
  self.value_right = value
  local val = self:_calculate_value(tonumber(self.value_left) or 0, tonumber(value) or 0)
  if val ~= val then val = 0 end -- replace NaN with 0
  self.value = val
  self.signal_out:inform(val)
end

function BaseMathFrame:on_connect(prop, from, value)
  if prop == "signal_left" then
    self.signal_left = from
    from:listen(self, prop, refresh_left)
    refresh_left(self, nil, value)
  elseif prop == "signal_right" then
    self.signal_right = from
    from:listen(self, prop, refresh_right)
    refresh_right(self, nil, value)
  end
end

function BaseMathFrame:on_disconnect(prop)
  if prop == "signal_left" then
    self.signal_left:unlisten(self, prop, refresh_left)
    self.signal_left = nil
    refresh_left(self, nil, 0)
  elseif prop == "signal_right" then
    self.signal_right:unlisten(self, prop, refresh_right)
    self.signal_right = nil
    refresh_right(self, nil, 0)
  end
end

function BaseMathFrame:draw(size_x, size_y, scale)
  love.graphics.setColor(0.4, 0.4, 0.4)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
  pleasure.push_region(0, 0, size_x, size_y)
  pleasure.translate(size_x/2, size_y/2)
  pleasure.scale(scale)
  self:draw_decor(size_x/scale, size_y/scale, scale)
  pleasure.pop_region()
end

function BaseMathFrame.draw_decor(size_x, size_y, scale) end

return BaseMathFrame
