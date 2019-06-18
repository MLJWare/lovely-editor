local Frame                   = require "Frame"
local IOs                     = require "IOs"
local VectorNKind             = require "Kind.VectorN"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local clamp                   = require "math.clamp"
local is                      = require "pleasure.is"

local is_table = is.table
local is_number = is.number
local is_table_of = is.table_of
local is_metakind = is.metakind

local MAX_SCALE = 8

local GraphFrame = {}
GraphFrame.__index = GraphFrame
GraphFrame._kind = ";GraphFrame;Frame;"

setmetatable(GraphFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "GraphFrame constructor must be a table.")
    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or 64
    GraphFrame.typecheck(frame, "GraphFrame constructor")
    frame.sizes = frame.sizes or {1, 1, 1, 1, 1, 1, 1, 1, count = 8}
    frame.sizes.count = math.min(#frame.sizes, frame.sizes.count)

    frame.signal_out = Signal {
      kind = VectorNKind;
      on_connect = function ()
        local sizes = frame.sizes
        return unpack(sizes, 1, sizes.count)
      end;
    }

    setmetatable(frame, GraphFrame)
    frame:refresh()
    return frame
  end;
})

function GraphFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  if obj.sizes then
    assertf(is_table_of(obj.sizes, is_number), "Error in %s: Invalid/missing property: 'sizes' must be a numeric table with a numeric 'count' property.", where)
    assertf(is_number(obj.sizes.count), "Error in %s: Invalid/missing property: 'count' property of 'sizes' must be a number.", where)
  end
end


function GraphFrame.is(obj)
  return is_metakind(obj, ";GraphFrame;")
end

GraphFrame.gives = IOs{
  {id = "signal_out", kind = VectorNKind};
}

local line_tmp = {}
function GraphFrame:draw(size_x, size_y, scale)
  local sizes = self.sizes
  local count = sizes.count

  love.graphics.push()
  local step = size_x/count
  local scalar = size_y/MAX_SCALE
  for i = 1, count do
    line_tmp[i*2 - 1] = step*(i - 0.5)
    line_tmp[i*2    ] = size_y - sizes[i]*scalar
  end

  local lw = love.graphics.getLineWidth()
  local ls = love.graphics.getLineStyle()
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("smooth")
  if count > 1 then
    love.graphics.line(unpack(line_tmp, 1, count*2))
  else
    local y = line_tmp[2]
    love.graphics.line(size_x/4, y, size_x*3/4, y)
  end
  love.graphics.setLineStyle(ls)
  love.graphics.setLineWidth(lw)

  local ps = love.graphics.getPointSize()
  love.graphics.setPointSize(3)
  love.graphics.points(unpack(line_tmp, 1, count*2))
  love.graphics.setPointSize(ps)
  love.graphics.pop()
end

function GraphFrame:refresh(_)
  local sizes = self.sizes
  self.signal_out:inform(unpack(sizes, 1, sizes.count))
end

function GraphFrame:mousepressed(mx, my, button)
  if button ~= 1 then return end
  self:request_focus()
  self:refresh_internal(mx, my)
end

function GraphFrame:mousedragged1(mx, my)
  self:refresh_internal(mx, my)
end

function GraphFrame:mousereleased(mx, my, button)
  if button ~= 1 then return end
  self:refresh_internal(mx, my)
end

function GraphFrame:refresh_internal (mx, my)
  local dy = self.size_y - my
  local sizes = self.sizes
  local count = sizes.count
  local index = 1 + math.floor((mx/self.size_x)*count)
  if 0 < index and index <= count then
    self.sizes[index] = clamp((dy/self.size_y)*MAX_SCALE, 0, MAX_SCALE)
  end
  self:refresh()
end

function GraphFrame:keypressed(key)
  local delta = ((key == "+" or key == "kp+") and 1 or 0)
              - ((key == "-" or key == "kp-") and 1 or 0)
  local sizes = self.sizes
  sizes.count = clamp(sizes.count + delta, 1, 8)
  self:refresh()
end

function GraphFrame:mousedragged(mx, my)
  self:update(mx, my)
  self:refresh()
end

function GraphFrame.id()
  return "Graph"
end

function GraphFrame:serialize()
  return ([=[GraphFrame {
    size_x = %s;
    size_y = %s;
    sizes = {%s, count = %s};
  }]=]):format(self.size_x, self.size_y, table.concat(self.sizes, ","), self.sizes.count)
end

return GraphFrame
