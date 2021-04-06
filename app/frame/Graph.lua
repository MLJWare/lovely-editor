local Frame                   = require "Frame"
local IOs                     = require "IOs"
local NumberPacketKind        = require "Kind.NumberPacket"
local Signal                  = require "Signal"
local assertf                 = require "assertf"
local clamp                   = require "math.clamp"
local is                      = require "pleasure.is"
local try_invoke              = require "pleasure.try".invoke

local is_table = is.table
local is_number = is.number
local is_table_of = is.table_of
local is_metakind = is.metakind

local MAX_SCALE = 8

---@class GraphFrame : Frame
---@field data number[] data points
---@field signal_out Signal output signal
local GraphFrame = {}
GraphFrame.__index = GraphFrame
GraphFrame._kind = ";GraphFrame;Frame;"

local function make_data(count)
  local data = {}
  for i = 1, count do
    data[i] = 0
  end
  data.count = count
  return data
end

setmetatable(GraphFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "GraphFrame constructor must be a table.")
    frame.size_x = frame.size_x or 64
    frame.size_y = frame.size_y or 64
    GraphFrame.typecheck(frame, "GraphFrame constructor")
    frame.data = frame.data or make_data(frame.size_x)
    frame.data.count = math.min(#frame.data, frame.data.count or math.huge)

    frame.signal_out = Signal {
      kind = NumberPacketKind;
      on_connect = function ()
        return frame.data_in or frame.data
      end;
    }

    setmetatable(frame, GraphFrame)
    frame:refresh()
    return frame
  end;
})

function GraphFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  if obj.data then
    assertf(is_table_of(obj.data, is_number), "Error in %s: Invalid/missing property: 'data' must be a numeric table with a numeric 'count' property.", where)
    assertf(is_number(obj.data.count), "Error in %s: Invalid/missing property: 'count' property of 'data' must be a number.", where)
  end
end

function GraphFrame.is(obj)
  return is_metakind(obj, ";GraphFrame;")
end

GraphFrame.takes = IOs{
  {id = "signal_in", kind = NumberPacketKind, hint = "data"};
}

GraphFrame.gives = IOs{
  {id = "signal_out", kind = NumberPacketKind, hint = "data"};
}

function GraphFrame:on_connect(prop, from, data)
  if prop == "signal_in" then
    self.signal_in = from
    from:listen(self, prop, self.refresh)
    self:refresh(prop, data)
  end
end

function GraphFrame:on_disconnect(prop)
  if prop == "signal_in" then
    try_invoke(self.signal_in, "unlisten", self, prop, self.refresh)
    self:refresh(prop, nil)
    self.signal_in = nil
  end
end

function GraphFrame:locked()
  return self.signal_in ~= nil
end

local line_tmp = {}
function GraphFrame:draw(size_x, size_y, scale)
  local data = self.data_in or self.data
  local data_count = data.count or #data

  local half_y = size_y/2

  love.graphics.push()
  local step = size_x/data_count
  local scalar = half_y/MAX_SCALE
  for i = 1, data_count do
    line_tmp[i*2 - 1] = step*(i - 0.5)
    line_tmp[i*2    ] = half_y - data[i]*scalar
  end

  local lw = love.graphics.getLineWidth()
  local ls = love.graphics.getLineStyle()
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("smooth")
  if data_count > 1 then
    love.graphics.line(unpack(line_tmp, 1, data_count*2))
  else
    local y = line_tmp[2]
    love.graphics.line(size_x/4, y, size_x*3/4, y)
  end
  love.graphics.setLineStyle(ls)
  love.graphics.setLineWidth(lw)

  -- local ps = love.graphics.getPointSize()
  -- love.graphics.setPointSize(3)
  -- love.graphics.points(unpack(line_tmp, 1, data_count*2))
  -- love.graphics.setPointSize(ps)
  love.graphics.pop()
end

function GraphFrame:refresh(_, data)
  self.data_in = data
  local data_out = self.data_in or self.data
  self.signal_out:inform(data_out)
end

function GraphFrame:mousepressed(mx, my, button)
  if button ~= 1 or self:locked() then return end
  self:request_focus()
  self:refresh_internal(mx, my, 0, 0)
end

function GraphFrame:mousedragged1(mx, my, dx, dy)
  if self:locked() then return end
  self:refresh_internal(mx, my, dx, dy)
end

function GraphFrame:mousereleased(mx, my, button)
  if button ~= 1 or self:locked() then return end
  self:refresh_internal(mx, my, 0, 0)
end

function GraphFrame:refresh_internal (mx, my, dx, dy)
  my = self.size_y - my -- flip y axis
  local data = self.data
  local data_count = data.count
  local size_x = self.size_x
  local half_y = self.size_y / 2
  local sign = dx < 0 and -1 or 1
  local x1 = mx - dx
  local x2 = mx
  for x = x1, x2, sign do
    local index = 1 + math.floor((x/size_x)*data_count + 0.5)
    if 0 < index and index <= data_count then
      local y = my + dy * math.abs(x2 - x)/math.max(math.abs(dx), 1)
      self.data[index] = clamp(((y/half_y) - 1)*MAX_SCALE, -MAX_SCALE, MAX_SCALE)
    end
  end
  --self:refresh()
end

function GraphFrame:keypressed(key)
  if self:locked() then return end
  -- local delta = ((key == "+" or key == "kp+") and 1 or 0)
  --             - ((key == "-" or key == "kp-") and 1 or 0)
  -- local data = self.data
  -- data.count = clamp(data.count + delta, 1, #data)
  if key == "return" then
    self:refresh()
  end
end

function GraphFrame.id()
  return "Graph"
end

function GraphFrame:serialize()
  return ([=[GraphFrame {
    size_x = %s;
    size_y = %s;
    data = {%s, count = %s};
  }]=]):format(self.size_x, self.size_y, table.concat(self.data, ","), self.data.count)
end

return GraphFrame
