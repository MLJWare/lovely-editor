local Frame                   = require "Frame"
local Signal                  = require "Signal"
local Vector2Kind             = require "Kind.Vector2"
local IOs                     = require "IOs"
local shift_is_down           = require "util.shift_is_down"
local is                      = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

local FULL_ROTATION = 2*math.pi

local AnglesFrame = {}
AnglesFrame.__index = AnglesFrame
AnglesFrame._kind = ";AnglesFrame;Frame;"

setmetatable(AnglesFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "AnglesFrame constructor must be a table.")

    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or frame.size_x
    AnglesFrame.typecheck(frame, "AnglesFrame constructor")

    frame.angle1 = (frame.angle1 or 0) % 1
    frame.angle2 = (frame.angle2 or 0) % 1
    frame.signal_out = Signal {
      kind = Vector2Kind;
      on_connect = function () return frame.angle1, frame.angle2 end;
    }

    setmetatable(frame, AnglesFrame)
    frame:refresh()
    return frame
  end;
})

function AnglesFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function AnglesFrame.is(obj)
  return is_metakind(obj, ";AnglesFrame;")
end

AnglesFrame.gives = IOs{
  {id = "signal_out", kind = Vector2Kind};
}

function AnglesFrame:draw(size_x, size_y, scale)
  local angle1 = self.angle1*FULL_ROTATION
  local angle2 = angle1 + self.angle2*FULL_ROTATION
  local len = math.min(size_x, size_y)*3/7

  local x1 = len*math.cos(angle1)
  local y1 = len*math.sin(angle1)

  local x2 = len*math.cos(angle2)
  local y2 = len*math.sin(angle2)

  local lw = love.graphics.getLineWidth()
  local ls = love.graphics.getLineStyle()
  love.graphics.push()
  love.graphics.translate(size_x/2, size_y/2)
  love.graphics.rotate(-FULL_ROTATION/4)
  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.arc("fill", "pie", 0, 0, len, angle1, angle2)
  love.graphics.setLineWidth(2)
  love.graphics.setLineStyle("smooth")
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.arc("line", "open", 0, 0, len, angle1, angle2)
  love.graphics.line(0, 0, x1, y1)
  love.graphics.line(0, 0, x2, y2)
  love.graphics.setLineStyle(ls)
  love.graphics.setLineWidth(lw)
  love.graphics.pop()
end

function AnglesFrame:refresh(_)
  self.signal_out:inform(self.angle1, self.angle2)
end

function AnglesFrame:mousepressed(mx, my, button)
  if button ~= 1 then return end
  self:request_focus()
  self:refresh_internal(mx, my, shift_is_down())
end

function AnglesFrame:mousedragged1(mx, my)
  self:refresh_internal(mx, my, shift_is_down())
end

function AnglesFrame:mousereleased(mx, my, button)
  if button ~= 1 then return end
  self:refresh_internal(mx, my, shift_is_down())
end

function AnglesFrame:refresh_internal (mx, my, secondary)
  local cx = self.size_x/2
  local cy = self.size_y/2
  local dx = mx - cx
  local dy = my - cy
  local rotation = math.atan2(dy, dx)/FULL_ROTATION + 0.25
  if rotation < 0 then rotation = rotation + 1 end
  if secondary then
    self.angle2 = (rotation - self.angle1) % 1
  else
    self.angle1 = rotation
  end
  self:refresh()
end

function AnglesFrame.id()
  return "Angles"
end

function AnglesFrame:serialize()
  return ([=[AnglesFrame {
    size_x = %s;
    size_y = %s;
    angle1 = %s;
    angle2 = %s;
  }]=]):format(self.size_x, self.size_y, self.angle1, self.angle2)
end

return AnglesFrame
