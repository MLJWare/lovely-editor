local clamp                   = require "math.clamp"
local is                      = require "pleasure.is"

local is_table  = is.table
local is_number = is.number

local MIN_SCALE = 0.1
local MAX_SCALE = 100

local Viewport = {
  show_connections = true;
}
Viewport.__index = Viewport

setmetatable(Viewport, {
  __call = function (_, viewport)
    local self = setmetatable(viewport, Viewport)

    assert(is_table(viewport), "Viewport must be a table.")
    assert(is_number(viewport.pos_x), "Viewport must have a numeric `pos_x` property.")
    assert(is_number(viewport.pos_y), "Viewport must have a numeric `pos_y` property.")
    assert(is_number(viewport.scale), "Viewport must have a numeric `scale` property.")

    return self
  end;
})

function Viewport:_serialize()
  return ([[Viewport {
    pos_x = %s;
    pos_y = %s;
    scale = %s;
    show_connections = %s;
  }]]):format(self.pos_x, self.pos_y, self.scale, self.show_connections)
end

function Viewport:set_position(x, y)
  self.pos_x = x
  self.pos_y = y
end

function Viewport:global_size_of(view)
  local frame = view.frame
  local scale = view.scale*self.scale
  return frame.size_x*scale, frame.size_y*scale
end

function Viewport:local_to_global_pos(pos_x, pos_y)
  local scale = self.scale
  return (pos_x - self.pos_x)*scale
       , (pos_y - self.pos_y)*scale
end

function Viewport:global_to_local_pos(pos_x, pos_y)
  local scale = self.scale
  return pos_x/scale + self.pos_x
       , pos_y/scale + self.pos_y
end

function Viewport:position_in_view_space(pos_x, pos_y, view)
  if not view.anchored then
    pos_x, pos_y = self:global_to_local_pos(pos_x, pos_y)
  end
  local view_scale = view.scale
  return (pos_x - view.pos_x)/view_scale
       , (pos_y - view.pos_y)/view_scale
end

function Viewport:view_at_global_pos(pos_x, pos_y, views, include_border)
  for _, view in ipairs(views) do
    local pos2_x, pos2_y, size_x, size_y = self:view_bounds(view, include_border)
    if  pos2_x <= pos_x
    and pos2_y <= pos_y
    and pos_x < pos2_x + size_x
    and pos_y < pos2_y + size_y then
      return view
    end
  end
end

function Viewport.global_mouse()
  return love.mouse.getPosition()
end

function Viewport:scale_view(view, scalar)
  self:set_view_scale(view, view.scale*(1 + scalar))
end

function Viewport:set_view_scale(view, new_scale)
  local mouse_x, mouse_y = self.global_mouse()
  if not view.anchored then
    mouse_x, mouse_y = self:global_to_local_pos(mouse_x, mouse_y)
  end

  local old_scale = view.scale
  new_scale = clamp(new_scale, MIN_SCALE, MAX_SCALE)
  local delta_scale = new_scale/old_scale

  view.scale = new_scale
  view.pos_x = mouse_x - (mouse_x - view.pos_x)*delta_scale
  view.pos_y = mouse_y - (mouse_y - view.pos_y)*delta_scale
end

function Viewport:scale_viewport(scalar)
  self:set_viewport_scale(self.scale*(1 + scalar))
end

function Viewport:set_viewport_scale(new_scale)
  local mouse_x, mouse_y = self.global_mouse()
  local old_scale = self.scale
  new_scale = clamp(new_scale, MIN_SCALE, MAX_SCALE)

  local viewport_w, viewport_h = love.graphics.getDimensions()
  local old_w = viewport_w/old_scale
  local old_h = viewport_h/old_scale

  local new_w = viewport_w/new_scale
  local new_h = viewport_h/new_scale

  local pct_x = mouse_x / viewport_w
  local pct_y = mouse_y / viewport_h

  self.scale = new_scale
  self.pos_x = self.pos_x + (old_w - new_w)*pct_x
  self.pos_y = self.pos_y + (old_h - new_h)*pct_y
end

function Viewport:view_bounds(view, include_border)
  local pos2_x, pos2_y, size_x, size_y, scale
  local view_scale = view.scale

  if view.anchored then
    local frame = view.frame
    pos2_x = view.pos_x
    pos2_y = view.pos_y
    size_x = frame.size_x*view_scale
    size_y = frame.size_y*view_scale
    scale = view_scale
  else
    pos2_x, pos2_y = self:local_to_global_pos(view.pos_x, view.pos_y)
    size_x, size_y = self:global_size_of(view)
    scale = view_scale*self.scale
  end

  assert(size_x >= 0 and size_y >= 0)

  if include_border then
    return pos2_x - 4, pos2_y - 20, size_x + 8, size_y + 28, scale
  else
    return pos2_x, pos2_y, size_x, size_y, scale
  end
end

function Viewport:view_render_scale(view)
  if view.anchored then
    return view.scale
  end
  return view.scale*self.scale
end

function Viewport:lock_view(view)
  if view.anchored then return end
  local own_scale = self.scale
  view.anchored = true
  view.scale = view.scale*own_scale
  view.pos_x = (view.pos_x - self.pos_x)*own_scale
  view.pos_y = (view.pos_y - self.pos_y)*own_scale
end

function Viewport:unlock_view(view)
  if not view.anchored then return end
  local own_scale = self.scale
  view.anchored = nil
  view.scale = view.scale/own_scale
  view.pos_x = view.pos_x/own_scale + self.pos_x
  view.pos_y = view.pos_y/own_scale + self.pos_y
end

function Viewport:pan_viewport(dx, dy)
  local scale = self.scale
  self.pos_x = self.pos_x - dx/scale
  self.pos_y = self.pos_y - dy/scale
end

function Viewport:move_view(view, dx, dy)
  if view.anchored then
    view.pos_x = view.pos_x + dx
    view.pos_y = view.pos_y + dy
  else
    local own_scale = self.scale
    view.pos_x = view.pos_x + dx/own_scale
    view.pos_y = view.pos_y + dy/own_scale
  end
end

return Viewport
