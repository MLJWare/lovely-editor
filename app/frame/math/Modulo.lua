local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberPacket            = require "packet.Number"
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

    frame.value = NumberPacket{ value = 0 }

    setmetatable(Frame(frame), ModuloFrame)
    return frame
  end;
})

function ModuloFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(not obj.value or NumberPacket.is(obj.value), "Error in %s: Missing/invalid property: 'value' must be a NumberPacket.", where)
end

function ModuloFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ModuloFrame;")
end

ModuloFrame.takes = IOs{
  {id = "left" , kind = NumberPacket};
  {id = "right", kind = NumberPacket};
}

ModuloFrame.gives = IOs{
  {id = "value", kind = NumberPacket};
}

function ModuloFrame:on_connect(prop, from)
  if prop == "left" then
    self.left = from
    from:listen(self, self.refresh)
    self:refresh()
  elseif prop == "right" then
    self.right = from
    from:listen(self, self.refresh)
    self:refresh()
  end
end

function ModuloFrame:on_disconnect(prop)
  if prop == "left" then
    self.left:unlisten(self, self.refresh)
    self.left = nil
    self:refresh()
  elseif prop == "right" then
    self.right:unlisten(self, self.refresh)
    self.right = nil
    self:refresh()
  end
end

function ModuloFrame:draw(size, scale)
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)
  local text = tostring(self.value.value)
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
  return v and tonumber(v.value) or 0
end

function ModuloFrame:refresh()
  self.value.value = _num(self.left) % _num(self.right)
  self.value:inform()
end

function ModuloFrame:serialize()
  return "ModuloFrame {}"
end

function ModuloFrame.id()
  return "Modulo"
end

return ModuloFrame
