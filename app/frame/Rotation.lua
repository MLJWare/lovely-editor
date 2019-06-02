local Frame                   = require "Frame"
local Signal                  = require "Signal"
local NumberKind              = require "Kind.Number"
local IOs                     = require "IOs"

local FULL_ROTATION = 2*math.pi

local RotationFrame = {}
RotationFrame.__index = RotationFrame

RotationFrame._kind = ";RotationFrame;Frame;"

setmetatable(RotationFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "RotationFrame constructor must be a table.")

    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or frame.size_x
    RotationFrame.typecheck(frame, "RotationFrame constructor")

    frame.rotation = (frame.rotation or 0) % 1
    frame.signal_out = Signal {
      kind = NumberKind;
      on_connect = function () return frame.rotation end;
    }
    setmetatable(frame, RotationFrame)
    frame:refresh()
    return frame
  end;
})

function RotationFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function RotationFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";RotationFrame;")
end

RotationFrame.gives = IOs{
  {id = "signal_out", kind = NumberKind};
}

function RotationFrame:draw(size_x, size_y, scale)
  local angle = self.rotation*FULL_ROTATION
  local len = math.min(size_x, size_y)*3/7

  local cx = size_x/2
  local cy = size_y/2
  local x2 = len*math.cos(angle)
  local y2 = len*math.sin(angle)
  local lw = love.graphics.getLineWidth()
  local ls = love.graphics.getLineStyle()
  love.graphics.push()
  love.graphics.translate(cx, cy)
  love.graphics.rotate(-FULL_ROTATION/4)
  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.arc("fill", "pie", 0, 0, len, 0, angle)
  love.graphics.setLineWidth(2)
  love.graphics.setLineStyle("smooth")
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.arc("line", "open", 0, 0, len, 0, angle)
  love.graphics.line(0, 0, len, 0)
  love.graphics.line(0, 0, x2, y2)
  love.graphics.setLineStyle(ls)
  love.graphics.setLineWidth(lw)
  love.graphics.pop()
end

function RotationFrame:refresh(_)
  self.signal_out:inform(self.rotation)
end

function RotationFrame:mousepressed(mx, my, button)
  if button ~= 1 then return end
  self:request_focus()
  self:refresh_internal(mx, my)
end

function RotationFrame:mousedragged1(mx, my)
  self:refresh_internal(mx, my)
end

function RotationFrame:mousereleased(mx, my, button)
  if button ~= 1 then return end
  self:refresh_internal(mx, my)
end

function RotationFrame:refresh_internal (mx, my)
  local cx = self.size_x/2
  local cy = self.size_y/2
  local dx = mx - cx
  local dy = my - cy
  local rotation = math.atan2(dy, dx)/FULL_ROTATION + 0.25
  if rotation < 0 then rotation = rotation + 1 end
  self.rotation = rotation
  self:refresh()
end

function RotationFrame.id()
  return "Rotation"
end

function RotationFrame:serialize()
  return ([=[RotationFrame {
    size_x = %s;
    size_y = %s;
    rotation = %s;
  }]=]):format(self.size_x, self.size_y, self.rotation)
end

return RotationFrame
