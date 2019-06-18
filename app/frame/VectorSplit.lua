local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local VectorNKind             = require "Kind.VectorN"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local VectorSplitFrame = {}
VectorSplitFrame.__index = VectorSplitFrame
VectorSplitFrame._kind = ";VectorSplitFrame;Frame;"

setmetatable(VectorSplitFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "VectorSplitFrame constructor must be a table.")
    frame.size_x = 20
    frame.size_y = 96
    VectorSplitFrame.typecheck(frame, "VectorSplitFrame constructor")

    frame.value1 = frame.value1 or 0
    frame.signal_out1 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value1 end;
    }

    frame.value2 = frame.value2 or 0
    frame.signal_out2 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value2 end;
    }

    frame.value3 = frame.value3 or 0
    frame.signal_out3 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value3 end;
    }

    frame.value4 = frame.value4 or 0
    frame.signal_out4 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value4 end;
    }

    frame.value5 = frame.value5 or 0
    frame.signal_out5 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value5 end;
    }

    frame.value6 = frame.value6 or 0
    frame.signal_out6 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value6 end;
    }

    frame.value7 = frame.value7 or 0
    frame.signal_out7 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value7 end;
    }

    frame.value8 = frame.value8 or 0
    frame.signal_out8 = Signal {
      kind = NumberKind;
      on_connect = function () return frame.value8 end;
    }

    setmetatable(Frame(frame), VectorSplitFrame)

    return frame
  end;
})

function VectorSplitFrame.typecheck(obj, where)
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

function VectorSplitFrame.is(obj)
  return is_metakind(obj, ";VectorSplitFrame;")
end

VectorSplitFrame.gives = IOs{
  {id = "signal_out1", kind = NumberKind};
  {id = "signal_out2", kind = NumberKind};
  {id = "signal_out3", kind = NumberKind};
  {id = "signal_out4", kind = NumberKind};
  {id = "signal_out5", kind = NumberKind};
  {id = "signal_out6", kind = NumberKind};
  {id = "signal_out7", kind = NumberKind};
  {id = "signal_out8", kind = NumberKind};
}

VectorSplitFrame.takes = IOs{
  {id = "signal_in", kind = VectorNKind};
}

function VectorSplitFrame:on_connect(prop, from, x, y, z, w, a, b, c, d)
  if prop == "signal_in" then
    self.signal_in = from
    from:listen(self, prop, self.refresh)
    self:refresh(prop, x, y, z, w, a, b, c, d)
  end
end

function VectorSplitFrame:on_disconnect(prop)
  if prop == "signal_in" then
    try_invoke(self.signal_in, "unlisten", self, prop, self.refresh)
    self.signal_in = nil
    self:refresh(prop, 0, 0, 0, 0, 0, 0, 0, 0)
  end
end

function VectorSplitFrame:draw(size_x, size_y, _)
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
end

function VectorSplitFrame:refresh(_, v1, v2, v3, v4, v5, v6, v7, v8)
  local new1 = v1 or 0
  if new1 ~= self.value1 then
    self.value1 = new1
    self.signal_out1:inform(new1)
  end
  local new2 = v2 or 0
  if new2 ~= self.value2 then
    self.value2 = new2
    self.signal_out2:inform(new2)
  end
  local new3 = v3 or 0
  if new3 ~= self.value3 then
    self.value3 = new3
    self.signal_out3:inform(new3)
  end
  local new4 = v4 or 0
  if new4 ~= self.value4 then
    self.value4 = new4
    self.signal_out4:inform(new4)
  end
  local new5 = v5 or 0
  if new5 ~= self.value5 then
    self.value5 = new5
    self.signal_out5:inform(new5)
  end
  local new6 = v6 or 0
  if new6 ~= self.value6 then
    self.value6 = new6
    self.signal_out6:inform(new6)
  end
  local new7 = v7 or 0
  if new7 ~= self.value7 then
    self.value7 = new7
    self.signal_out7:inform(new7)
  end
  local new8 = v8 or 0
  if new8 ~= self.value8 then
    self.value8 = new8
    self.signal_out8:inform(new8)
  end
end

function VectorSplitFrame:serialize()
  return ([[VectorSplitFrame {
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

function VectorSplitFrame.id()
  return "Vector Split"
end

return VectorSplitFrame
