local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Vector2Kind             = require "Kind.Vector2"
local Vector3Kind             = require "Kind.Vector3"
local Vector4Kind             = require "Kind.Vector4"
local Vector5Kind             = require "Kind.Vector5"
local Vector6Kind             = require "Kind.Vector6"
local Vector7Kind             = require "Kind.Vector7"
local Vector8Kind             = require "Kind.Vector8"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local VectorJoinFrame = {}
VectorJoinFrame.__index = VectorJoinFrame
VectorJoinFrame._kind = ";VectorJoinFrame;Frame;"

setmetatable(VectorJoinFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "VectorJoinFrame constructor must be a table.")
    frame.size_x = 20
    frame.size_y = 96
    VectorJoinFrame.typecheck(frame, "VectorJoinFrame constructor")

    frame.value1 = frame.value1 or 0
    frame.value2 = frame.value2 or 0
    frame.value3 = frame.value3 or 0
    frame.value4 = frame.value4 or 0
    frame.value5 = frame.value5 or 0
    frame.value6 = frame.value6 or 0
    frame.value7 = frame.value7 or 0
    frame.value8 = frame.value8 or 0

    frame.signal_out = Signal {
      kind = Vector8Kind;
      on_connect = function ()
        return frame.value1
             , frame.value2
             , frame.value3
             , frame.value4
             , frame.value5
             , frame.value6
             , frame.value7
             , frame.value8
      end;
    }

    setmetatable(Frame(frame), VectorJoinFrame)

    return frame
  end;
})

function VectorJoinFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(is_opt(obj.value1, NumberKind.is), "Error in %s: Invalid optional property: 'value1' must be a number.", where)
  assertf(is_opt(obj.value2, NumberKind.is), "Error in %s: Invalid optional property: 'value2' must be a number.", where)
  assertf(is_opt(obj.value3, NumberKind.is), "Error in %s: Invalid optional property: 'value3' must be a number.", where)
  assertf(is_opt(obj.value4, NumberKind.is), "Error in %s: Invalid optional property: 'value4' must be a number.", where)
  assertf(is_opt(obj.value5, NumberKind.is), "Error in %s: Invalid optional property: 'value5' must be a number.", where)
  assertf(is_opt(obj.value6, NumberKind.is), "Error in %s: Invalid optional property: 'value6' must be a number.", where)
  assertf(is_opt(obj.value7, NumberKind.is), "Error in %s: Invalid optional property: 'value7' must be a number.", where)
  assertf(is_opt(obj.value8, NumberKind.is), "Error in %s: Invalid optional property: 'value8' must be a number.", where)
end

function VectorJoinFrame.is(obj)
  return is_metakind(obj, ";VectorJoinFrame;")
end

VectorJoinFrame.gives = IOs{
  {id = "signal_out", kind = Vector8Kind};
}

VectorJoinFrame.takes = IOs{
  {id = "signal_in1", kind = NumberKind};
  {id = "signal_in2", kind = NumberKind};
  {id = "signal_in3", kind = NumberKind};
  {id = "signal_in4", kind = NumberKind};
  {id = "signal_in5", kind = NumberKind};
  {id = "signal_in6", kind = NumberKind};
  {id = "signal_in7", kind = NumberKind};
  {id = "signal_in8", kind = NumberKind};
}

function VectorJoinFrame:on_connect(prop, from, data)
  if prop == "signal_in1" then
    self.signal_in1 = from
    from:listen(self, prop, self.refresh1)
    self:refresh1(prop, data)
  elseif prop == "signal_in2" then
    self.signal_in2 = from
    from:listen(self, prop, self.refresh2)
    self:refresh2(prop, data)
  elseif prop == "signal_in3" then
    self.signal_in3 = from
    from:listen(self, prop, self.refresh3)
    self:refresh3(prop, data)
  elseif prop == "signal_in4" then
    self.signal_in4 = from
    from:listen(self, prop, self.refresh4)
    self:refresh4(prop, data)
  elseif prop == "signal_in5" then
    self.signal_in5 = from
    from:listen(self, prop, self.refresh5)
    self:refresh5(prop, data)
  elseif prop == "signal_in6" then
    self.signal_in6 = from
    from:listen(self, prop, self.refresh6)
    self:refresh6(prop, data)
  elseif prop == "signal_in7" then
    self.signal_in7 = from
    from:listen(self, prop, self.refresh7)
    self:refresh7(prop, data)
  elseif prop == "signal_in8" then
    self.signal_in8 = from
    from:listen(self, prop, self.refresh8)
    self:refresh8(prop, data)
  end
end

function VectorJoinFrame:on_disconnect(prop)
  if prop == "signal_in1" then
    try_invoke(self.signal_in1, "unlisten", self, prop, self.refresh1)
    self.signal_in1 = nil
    self:refresh1(prop, 0)
  elseif prop == "signal_in2" then
    try_invoke(self.signal_in2, "unlisten", self, prop, self.refresh2)
    self.signal_in2 = nil
    self:refresh2(prop, 0)
  elseif prop == "signal_in3" then
    try_invoke(self.signal_in3, "unlisten", self, prop, self.refresh3)
    self.signal_in3 = nil
    self:refresh3(prop, 0)
  elseif prop == "signal_in4" then
    try_invoke(self.signal_in4, "unlisten", self, prop, self.refresh4)
    self.signal_in4 = nil
    self:refresh2(prop, 0)
  elseif prop == "signal_in5" then
    try_invoke(self.signal_in5, "unlisten", self, prop, self.refresh5)
    self.signal_in5 = nil
    self:refresh5(prop, 0)
  elseif prop == "signal_in6" then
    try_invoke(self.signal_in6, "unlisten", self, prop, self.refresh6)
    self.signal_in6 = nil
    self:refresh6(prop, 0)
  elseif prop == "signal_in7" then
    try_invoke(self.signal_in7, "unlisten", self, prop, self.refresh7)
    self.signal_in7 = nil
    self:refresh7(prop, 0)
  elseif prop == "signal_in8" then
    try_invoke(self.signal_in8, "unlisten", self, prop, self.refresh8)
    self.signal_in8 = nil
    self:refresh8(prop, 0)
  end
end

function VectorJoinFrame:draw(size_x, size_y, _)
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
end

function VectorJoinFrame:_tell()
  self.signal_out:inform(
    self.value1,
    self.value2,
    self.value3,
    self.value4,
    self.value5,
    self.value6,
    self.value7,
    self.value8
  )
end

function VectorJoinFrame:refresh1(_, v1)
  local new1 = v1 or 0
  if new1 ~= self.value1 then
    self.value1 = new1
    self:_tell()
  end
end

function VectorJoinFrame:refresh2(_, v2)
  local new2 = v2 or 0
  if new2 ~= self.value2 then
    self.value2 = new2
    self:_tell()
  end
end

function VectorJoinFrame:refresh3(_, v3)
  local new3 = v3 or 0
  if new3 ~= self.value3 then
    self.value3 = new3
    self:_tell()
  end
end

function VectorJoinFrame:refresh4(_, v4)
  local new4 = v4 or 0
  if new4 ~= self.value4 then
    self.value4 = new4
    self:_tell()
  end
end

function VectorJoinFrame:refresh5(_, v5)
  local new5 = v5 or 0
  if new5 ~= self.value5 then
    self.value5 = new5
    self:_tell()
  end
end

function VectorJoinFrame:refresh6(_, v6)
  local new6 = v6 or 0
  if new6 ~= self.value6 then
    self.value6 = new6
    self:_tell()
  end
end

function VectorJoinFrame:refresh7(_, v7)
  local new7 = v7 or 0
  if new7 ~= self.value7 then
    self.value7 = new7
    self:_tell()
  end
end

function VectorJoinFrame:refresh8(_, v8)
  local new8 = v8 or 0
  if new8 ~= self.value8 then
    self.value8 = new8
    self:_tell()
  end
end

function VectorJoinFrame:serialize()
  return ([[VectorJoinFrame {
    value1 = %s;
    value2 = %s;
    value3 = %s;
    value4 = %s;
    value5 = %s;
    value6 = %s;
    value7 = %s;
    value8 = %s;
  }]]):format(tostring(self.value1)
            , tostring(self.value2)
            , tostring(self.value3)
            , tostring(self.value4)
            , tostring(self.value5)
            , tostring(self.value6)
            , tostring(self.value7)
            , tostring(self.value8))
end

function VectorJoinFrame.id()
  return "Vector Join"
end

return VectorJoinFrame
