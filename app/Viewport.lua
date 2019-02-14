local Viewport = {}
Viewport.__index = Viewport

setmetatable(Viewport, {
  __call = function (_, viewport)
    local self = setmetatable(viewport, Viewport)

    assert(type(viewport      ) == "table", "Viewport must be a table.")
    assert(type(viewport.pos_x) == "number", "Viewport must have a numeric `pos_x` property.")
    assert(type(viewport.pos_y) == "number", "Viewport must have a numeric `pos_y` property.")
    assert(type(viewport.scale) == "number", "Viewport must have a numeric `scale` property.")

    return self
  end;
})

function Viewport:_serialize()
  return ([[Viewport {
    pos_x = %s;
    pos_y = %s;
    scale = %s;
  }]]):format(self.pos_x, self.pos_y, self.scale)
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

function Viewport:view_at_global_pos(pos_x, pos_y, views)
  local pos2_x, pos2_y, size_x, size_y

  for _, view in ipairs(views) do
     if view.anchored then
      local frame = view.frame
      local view_scale = view.scale
      pos2_x = view.pos_x
      pos2_y = view.pos_y
      size_x = frame.size_x*view_scale
      size_y = frame.size_y*view_scale
    else
      pos2_x, pos2_y = self:local_to_global_pos(view.pos_x, view.pos_y)
      size_x, size_y = self:global_size_of(view)
    end
    if  pos2_x <= pos_x
    and pos2_y - 20 <= pos_y
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
  local mouse_x, mouse_y = self.global_mouse()
  if not view.anchored then
    mouse_x, mouse_y = self:global_to_local_pos(mouse_x, mouse_y)
  end

  local old_scale = view.scale
  local new_scale = math.max(0.1, old_scale * (1 + scalar))
  local delta_scale = new_scale/old_scale

  view.scale = new_scale
  view.pos_x = mouse_x - (mouse_x - view.pos_x)*delta_scale
  view.pos_y = mouse_y - (mouse_y - view.pos_y)*delta_scale
end

function Viewport:set_view_scale(view, new_scale)
  if not view then return end
  local mouse_x, mouse_y = self.global_mouse()
  if not view.anchored then
    mouse_x, mouse_y = self:global_to_local_pos(mouse_x, mouse_y)
  end

  local old_scale = view.scale
  new_scale = math.max(0.1, new_scale)
  local delta_scale = new_scale/old_scale

  view.scale = new_scale
  view.pos_x = mouse_x - (mouse_x - view.pos_x)*delta_scale
  view.pos_y = mouse_y - (mouse_y - view.pos_y)*delta_scale
end

function Viewport:scale_viewport(scalar)
  local mouse_x, mouse_y = self.global_mouse()
  local old_scale = self.scale
  local new_scale = math.max(0.1, old_scale * (1 + scalar))
  local delta_scale = old_scale/new_scale

  self.scale = new_scale
  self.pos_x = mouse_x - (mouse_x - self.pos_x)*delta_scale
  self.pos_y = mouse_y - (mouse_y - self.pos_y)*delta_scale
end

function Viewport:set_viewport_scale(new_scale)
  local mouse_x, mouse_y = self.global_mouse()
  local old_scale = self.scale
  new_scale = math.max(0.1, new_scale)
  local delta_scale = old_scale/new_scale

  self.scale = new_scale
  self.pos_x = mouse_x - (mouse_x - self.pos_x)*delta_scale
  self.pos_y = mouse_y - (mouse_y - self.pos_y)*delta_scale
end

function Viewport:view_bounds(view)
  local view_scale = view.scale

  if view.anchored then
    local frame = view.frame
    return view.pos_x, view.pos_y
         , frame.size_x*view_scale, frame.size_y*view_scale
         , view_scale
  end
  local pos_x, pos_y = self:local_to_global_pos(view.pos_x, view.pos_y)
  local size_x, size_y = self:global_size_of(view)
  return pos_x, pos_y, size_x, size_y, view_scale*self.scale
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
