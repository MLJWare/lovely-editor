local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberKind              = require "Kind.Number"
local Signal                  = require "Signal"
local vec2                    = require "linear-algebra.Vector2"
local assertf                 = require "assertf"
local pleasure                = require "pleasure"
local font_writer             = require "util.font_writer"

local font = love.graphics.newFont(12)

local ModuloFrame = {}
ModuloFrame.__index = ModuloFrame

ModuloFrame._kind = ";ModuloFrame;Frame;"

setmetatable(ModuloFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ModuloFrame constructor must be a table.")

    if not frame.size then frame.size = vec2(64, 20) end
    ModuloFrame.typecheck(frame, "ModuloFrame constructor")

    if not frame.value then
      frame.value = 0
    end
    frame.signal_out = Signal {
      kind = NumberKind;
      on_connect = function ()
        return frame.value;
      end;
    }

    setmetatable(Frame(frame), ModuloFrame)
    return frame
  end;
})

function ModuloFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberKind.is(obj.value), "Error in %s: Invalid optional property: 'value' must be a number.", where)
end

function ModuloFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ModuloFrame;")
end

ModuloFrame.takes = IOs{
  {id = "signal_left" , kind = NumberKind};
  {id = "signal_right", kind = NumberKind};
}


ModuloFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

function ModuloFrame:on_connect(prop, from, value)
  if prop == "signal_left" then
    self.signal_left = from
    from:listen(self, prop, self.refresh_left)
    self:refresh_left(value)
  elseif prop == "signal_right" then
    self.signal_right = from
    from:listen(self, prop, self.refresh_right)
    self:refresh_right(value)
  end
end

function ModuloFrame:on_disconnect(prop)
  if prop == "signal_left" then
    self.signal_left:unlisten(self, prop, self.refresh_left)
    self.signal_left = nil
    self:refresh_left(nil)
  elseif prop == "signal_right" then
    self.signal_right:unlisten(self, prop, self.refresh_right)
    self.signal_right = nil
    self:refresh_right(nil)
  end
end

function ModuloFrame:draw(size, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)
  local text = tostring(self.value)
  pleasure.push_region(0, 0, size.x, size.y)
  pleasure.scale(scale)
  do
    local center_y = size.y/2/scale
    love.graphics.setColor(0.0, 0.0, 0.0)
    font_writer.print_aligned(font, text, 0, center_y, "left", "center")
  end
  pleasure.pop_region()
end

local function _num(v)
  return v and tonumber(v) or 0
end

function ModuloFrame:refresh_left(value)
  self.value_left = value
  local val = _num(value) % _num(self.value_right)
  if val ~= val then val = 0 end -- replace NaN with 0
  self.value = val
  self.signal_out:inform(val)
end

function ModuloFrame:refresh_right(value)
  self.value_right = value
  local val = _num(self.value_left) % _num(value)
  if val ~= val then val = 0 end -- replace NaN with 0
  self.value = val
  self.signal_out:inform(val)
end

function ModuloFrame.serialize()
  return "ModuloFrame {}"
end

function ModuloFrame.id()
  return "Modulo"
end

return ModuloFrame
