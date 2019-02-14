local vec2 = require "linear-algebra.Vector2"

local Viewport = {}
Viewport.__index = Viewport

setmetatable(Viewport, {
  __call = function (_, viewport)
    local self = setmetatable(viewport, Viewport)

    assert(type(viewport      ) == "table", "Viewport must be a table.")
    assert(vec2.is(viewport.pos)          , "Viewport must have a `pos` property of type `Vector2`.")
    assert(type(viewport.scale) == "number", "Viewport must have a numeric `scale` property.")

    return self
  end;
})

function Viewport:_serialize()
  return ([[Viewport {
    pos = %s;
    scale = %s;
  }]]):format(self.pos:serialize(), self.scale)
end

function Viewport:set_position(x, y)
  self.pos:setn(x, y)
end

function Viewport:global_size_of(view)
  local size = view.frame.size
  local scale = view.scale*self.scale
  return size.x*scale, size.y*scale
end

function Viewport:local_to_global_pos(pos_x, pos_y)
  local own_pos = self.pos
  local scale = self.scale
  return (pos_x - own_pos.x)*scale
       , (pos_y - own_pos.y)*scale
end

function Viewport:global_to_local_pos(pos_x, pos_y)
  local own_pos = self.pos
  local scale = self.scale
  return pos_x/scale + own_pos.x
       , pos_y/scale + own_pos.y
end

function Viewport:position_in_view_space(pos_x, pos_y, view)
  if not view.anchored then
    pos_x, pos_y = self:global_to_local_pos(pos_x, pos_y)
  end
  local view_pos = view.pos
  local view_scale = view.scale
  return (pos_x - view_pos.x)/view_scale
       , (pos_y - view_pos.y)/view_scale
end

function Viewport:view_at_global_pos(pos_x, pos_y, views)
  local pos2_x, pos2_y, size_x, size_y

  for _, view in ipairs(views) do
    local view_pos = view.pos
     if view.anchored then
      local frame_size = view.frame.size
      local view_scale = view.scale
      pos2_x = view_pos.x
      pos2_y = view_pos.y
      size_x = frame_size.x*view_scale
      size_y = frame_size.y*view_scale
    else
      pos2_x, pos2_y = self:local_to_global_pos(view_pos.x, view_pos.y)
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

  local view_pos = view.pos
  view.scale = new_scale
  view_pos.x = mouse_x - (mouse_x - view_pos.x)*delta_scale
  view_pos.y = mouse_y - (mouse_y - view_pos.y)*delta_scale
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

  local view_pos = view.pos
  view.scale = new_scale
  view_pos.x = mouse_x - (mouse_x - view_pos.x)*delta_scale
  view_pos.y = mouse_y - (mouse_y - view_pos.y)*delta_scale
end

function Viewport:scale_viewport(scalar)
  local mouse_x, mouse_y = self.global_mouse()
  local old_scale = self.scale
  local new_scale = math.max(0.1, old_scale * (1 + scalar))
  local delta_scale = old_scale/new_scale

  local own_pos = self.pos
  self.scale = new_scale
  own_pos.x = mouse_x - (mouse_x - own_pos.x)*delta_scale
  own_pos.y = mouse_y - (mouse_y - own_pos.y)*delta_scale
end

function Viewport:set_viewport_scale(new_scale)
  local mouse_x, mouse_y = self.global_mouse()
  local old_scale = self.scale
  new_scale = math.max(0.1, new_scale)
  local delta_scale = old_scale/new_scale

  local own_pos = self.pos
  self.scale = new_scale
  own_pos.x = mouse_x - (mouse_x - own_pos.x)*delta_scale
  own_pos.y = mouse_y - (mouse_y - own_pos.y)*delta_scale
end

function Viewport:view_bounds(view)
  local view_pos = view.pos
  local view_scale = view.scale

  if view.anchored then
    local frame_size = view.frame.size
    return view_pos.x, view_pos.y
         , frame_size.x*view_scale, frame_size.y*view_scale
         , view_scale
  end
  local pos_x, pos_y = self:local_to_global_pos(view_pos.x, view_pos.y)
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
  local view_pos = view.pos
  local own_pos = self.pos
  local own_scale = self.scale
  view.anchored = true
  view.scale = view.scale*own_scale
  view_pos.x = (view_pos.x - own_pos.x)*own_scale
  view_pos.y = (view_pos.y - own_pos.y)*own_scale
end

function Viewport:unlock_view(view)
  if not view.anchored then return end
  local view_pos = view.pos
  local own_pos = self.pos
  local own_scale = self.scale
  view.anchored = nil
  view.scale = view.scale/own_scale
  view_pos.x = view_pos.x/own_scale + own_pos.x
  view_pos.y = view_pos.y/own_scale + own_pos.y
end

function Viewport:pan_viewport(dx, dy)
  local pos = self.pos
  local scale = self.scale
  pos.x = pos.x - dx/scale
  pos.y = pos.y - dy/scale
end

function Viewport:move_view(view, dx, dy)
  local view_pos = view.pos

  if view.anchored then
    view_pos.x = view_pos.x + dx
    view_pos.y = view_pos.y + dy
  else
    local own_scale = self.scale
    view_pos.x = view_pos.x + dx/own_scale
    view_pos.y = view_pos.y + dy/own_scale
  end
end

return Viewport
