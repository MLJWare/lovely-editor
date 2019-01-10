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
  return view.frame.size*view.scale*self.scale
end

function Viewport:local_to_global_pos(pos)
  return (pos - self.pos)*self.scale
end

function Viewport:global_to_local_pos(pos)
  return pos/self.scale + self.pos
end

function Viewport:position_in_view_space(pos, view)
  local pos2 = view.anchored and pos or self:global_to_local_pos(pos)
  return (pos2 - view.pos)/view.scale
end

function Viewport:view_at_global_pos(pos, views)
  local pos2, size

  for _, view in ipairs(views) do
     if view.anchored then
      pos2 = view.pos
      size = view.frame.size*view.scale
    else
      pos2 = self:local_to_global_pos(view.pos)
      size = self:global_size_of(view)
    end
    if  pos2 <= pos and pos < pos2 + size then
      return view
    end
  end
end

function Viewport.global_mouse()
  return vec2(love.mouse.getPosition())
end

function Viewport:scale_view(view, scalar)
  local mouse = self.global_mouse()
  if not view.anchored then
    mouse = self:global_to_local_pos(mouse)
  end

  local old_scale = view.scale
  local new_scale = math.max(0.1, old_scale * (1 + scalar))

  view.scale = new_scale
  view.pos = mouse - (mouse - view.pos)*(new_scale/old_scale)
end

function Viewport:set_view_scale(view, new_scale)
  if not view then return end
  local mouse = self.global_mouse()
  if not view.anchored then
    mouse = self:global_to_local_pos(mouse)
  end

  local old_scale = view.scale
  new_scale = math.max(0.1, new_scale)

  view.scale = new_scale
  view.pos = mouse - (mouse - view.pos)*(new_scale/old_scale)
end

function Viewport:scale_viewport(scalar)
  local mouse = self.global_mouse()
  local old_scale = self.scale
  local new_scale = math.max(0.1, old_scale * (1 + scalar))

  self.scale = new_scale
  self.pos = mouse - (mouse - self.pos)*(old_scale/new_scale)
end

function Viewport:set_viewport_scale(new_scale)
  local mouse = self.global_mouse()
  local old_scale = self.scale
  new_scale = math.max(0.1, new_scale)

  self.scale = new_scale
  self.pos = mouse - (mouse - self.pos)*(old_scale/new_scale)
end

function Viewport:view_bounds(view)
  if view.anchored then
    return view.pos, view.frame.size*view.scale, view.scale
  end
  return self:local_to_global_pos(view.pos), self:global_size_of(view), view.scale*self.scale
end

function Viewport:view_render_scale(view)
  if view.anchored then
    return view.scale
  end
  return view.scale*self.scale
end

function Viewport:lock_view(view)
  if view.anchored then return end
  view.anchored = true
  view.scale = view.scale*self.scale
  view.pos = (view.pos - self.pos)*self.scale
end

function Viewport:unlock_view(view)
  if not view.anchored then return end
  view.anchored = nil
  view.scale = view.scale/self.scale
  view.pos = view.pos/self.scale + self.pos
end

function Viewport:pan_viewport(delta)
  self.pos:subv (delta/self.scale)
end

function Viewport:move_view(view, delta)
  view.pos:addv (view.anchored and delta or delta/self.scale)
end

return Viewport
