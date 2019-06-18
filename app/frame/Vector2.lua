local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Vector2Kind             = require "Kind.Vector2"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local Vector2Frame = {}
Vector2Frame.__index = Vector2Frame
Vector2Frame._kind = ";Vector2Frame;Frame;"

setmetatable(Vector2Frame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "Vector2Frame constructor must be a table.")
    frame.size_x = 20
    frame.size_y = 32
    Vector2Frame.typecheck(frame, "Vector2Frame constructor")

    frame.value1 = frame.value1 or 0
    frame.value2 = frame.value2 or 0
    frame.signal_out = Signal {
      kind = Vector2Kind;
      on_connect = function () return frame.value1, frame.value2 end;
    }

    setmetatable(Frame(frame), Vector2Frame)

    return frame
  end;
})

function Vector2Frame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(is_opt(obj.value1, NumberKind.is), "Error in %s: Invalid optional property: 'value1' must be a number.", where)
  assertf(is_opt(obj.value2, NumberKind.is), "Error in %s: Invalid optional property: 'value2' must be a number.", where)
end

function Vector2Frame.is(obj)
  return is_metakind(obj, ";Vector2Frame;")
end

Vector2Frame.gives = IOs{
  {id = "signal_out", kind = Vector2Kind};
}

Vector2Frame.takes = IOs{
  {id = "signal_in1", kind = NumberKind};
  {id = "signal_in2", kind = NumberKind};
}

function Vector2Frame:on_connect(prop, from, data)
  if prop == "signal_in1" then
    self.signal_in1 = from
    from:listen(self, prop, self.refresh1)
    self:refresh1(prop, data)
  elseif prop == "signal_in2" then
    self.signal_in2 = from
    from:listen(self, prop, self.refresh2)
    self:refresh2(prop, data)
  end
end

function Vector2Frame:on_disconnect(prop)
  if prop == "signal_in1" then
    try_invoke(self.signal_in1, "unlisten", self, prop, self.refresh1)
    self.signal_in1 = nil
    self:refresh1(prop, 0)
  elseif prop == "signal_in2" then
    try_invoke(self.signal_in2, "unlisten", self, prop, self.refresh2)
    self.signal_in2 = nil
    self:refresh2(prop, 0)
  end
end

function Vector2Frame:draw(size_x, size_y, _)
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
end

function Vector2Frame:refresh1(_, v1)
  local new1 = v1 or 0
  if new1 ~= self.value1 then
    self.value1 = new1
    self.signal_out:inform(new1, self.value2)
  end
end

function Vector2Frame:refresh2(_, v2)
  local new2 = v2 or 0
  if new2 ~= self.value2 then
    self.value2 = new2
    self.signal_out:inform(self.value1, new2)
  end
end

function Vector2Frame.serialize()
  return "Vector2Frame {}"
end

function Vector2Frame.id()
  return "Vector2"
end

return Vector2Frame
