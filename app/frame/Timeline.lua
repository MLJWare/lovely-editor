local Frame                   = require "Frame"
local IOs                     = require "IOs"
local Signal                  = require "Signal"
local NumberKind              = require "Kind.Number"
local ImageKind               = require "Kind.Image"
local EditImageKind           = require "Kind.EditImage"
local EditImagePacket         = require "packet.EditImage"
local vec2                    = require "linear-algebra.Vector2"

local TimelineFrame = {}
TimelineFrame.__index = TimelineFrame

TimelineFrame._kind = ";TimelineFrame;Frame;"

setmetatable(TimelineFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "TimelineFrame constructor must be a table.")

    if not frame.size then
      frame.size = vec2(32, 512)
    end

    TimelineFrame.typecheck(frame, "TimelineFrame constructor")

    frame.signal_anim = Signal {
      on_connect = function ()
        return frame.frame_anim
      end;
      kind = ImageKind;
    }
    frame.signal_edit = Signal {
      on_connect = function ()
        return frame.frame_active
      end;
      kind = ImageKind;
    }

    local anim_frames = {}
    for i = 1, 16 do
      anim_frames[i] = EditImagePacket {
        data = love.image.newImageData(64, 64);
      }
    end

    frame._anim = 0

    frame.anim_frames = anim_frames
    frame.frame_active = anim_frames[1]
    frame.frame_anim = anim_frames[1]

    setmetatable(frame, TimelineFrame)
    return frame
  end;
})

function TimelineFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(type(obj.value) == "number", "Error in %s: Missing/invalid property: 'value' must be a number.", where)
end

function TimelineFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";TimelineFrame;")
end

TimelineFrame.takes = IOs{
  {id = "signal_tick"  , kind = NumberKind};
}

TimelineFrame.gives = IOs{
  {id = "signal_anim", kind = ImageKind};
  {id = "signal_edit", kind = EditImageKind};
}

function TimelineFrame:on_connect(prop, from, data)
  if prop == "signal_tick" then
    self.signal_tick = from
    from:listen(self, prop, self.refresh)
    self:refresh(data)
  end
end

function TimelineFrame:on_disconnect(prop)
  if prop == "signal_tick" then
    self.signal_tick:unlisten(self, prop, self.refresh)
    self.signal_tick = nil
    self:refresh(nil)
  end
end

local function int(x)
  local val = math.floor(x or 0)
  if val ~= val then return 0 end
  return val
end

function TimelineFrame:refresh(tick)
  local anim_frames = self.anim_frames
  local prev_anim = self._anim
  local new_anim  = int(tick) % #anim_frames
  if prev_anim == new_anim then return end
  self._anim = new_anim
  local frame_anim = anim_frames[1 + self._anim].value
  self.frame_anim = frame_anim
  self.signal_anim:inform(frame_anim)
end

local row_height = 32

function TimelineFrame:draw(size, scale)
  local anim = self._anim
  love.graphics.setColor(0.2, 0.2, 0.2)
  love.graphics.rectangle("fill", 0, 0, size.x, size.y)

  local height = row_height * scale
  local active_index = self._active_index
  if active_index then
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, active_index*height, size.x, height)
  end

  love.graphics.setColor(0.8, 0.7, 0.2)
  love.graphics.rectangle("line", 0, anim*height, size.x, height)
end

function TimelineFrame:mousepressed(_, my, _)
  self:request_focus()

  local anim_frames  = self.anim_frames
  local new_active_index = math.max(0, math.min(math.floor(my/row_height), #anim_frames))
  local old_active_index = self._active_index

  if old_active_index == new_active_index then return end
  self._active_index = new_active_index
  local frame_active = anim_frames[1 + self._active_index]
  self.frame_active = frame_active
  self.signal_edit:inform(frame_active)
end

function TimelineFrame.serialize()
  return "TimelineFrame {}"
end

return TimelineFrame
