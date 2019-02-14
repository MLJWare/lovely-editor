local checker_pattern         = require "checker_pattern"
local FocusHandler            = require "FocusHandler"
local ImageKind               = require "Kind.Image"
local EditImageKind           = require "Kind.EditImage"
local StringKind              = require "Kind.String"
local NumberKind              = require "Kind.Number"
local Vector4Kind             = require "Kind.Vector4"
local MouseButton             = require "const.MouseButton"
local PixelFrame              = require "frame.Pixel"
local pleasure                = require "pleasure"
local Popup                   = require "Popup"
local Ref                     = require "Ref"
local remove_once             = require "util.list.remove_once"
local TextBufferFrame         = require "frame.TextBuffer"
local View                    = require "View"
local Viewport                = require "Viewport"
local Project                 = require "Project"

local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"

local shift_is_down           = require "util.shift_is_down"
local  ctrl_is_down           = require "util.ctrl_is_down"
local   alt_is_down           = require "util.alt_is_down"

local try_invoke              = pleasure.try.invoke

local pin_dragged = {
  view = nil;
  index = -1;
}

local EMPTY = {}

local settings = require "settings"

local default_checker_color      = pack_color(0.8, 0.8, 0.8, 1.0)
local default_transparency_color = pack_color(0.6, 0.6, 0.6, 1.0)
local default_checker_scale      = 8

local app = {
  project = Project{
    viewport = Viewport {
      pos_x  = 0;
      pos_y  = 0;
      scale  = 1;
    };
    views  = {};
    _links = {};
  };
  popups = {};

  menu   = {};

  focus_handler = FocusHandler ();

  show_connections = true;

  view_dragged   = nil;
  view_pressed1  = nil;
  view_pressed2  = nil;
  view_pressed3  = nil;
  popup_pressed1 = nil;
}

function app.restart()
  app.project = Project{
    viewport = Viewport {
      pos_x  = 0;
      pos_y  = 0;
      scale  = 1;
    };
    views  = {};
    _links = {};
  };
  app.focus_handler = FocusHandler ()
  app.view_dragged   = nil
  app.view_pressed1  = nil
  app.view_pressed2  = nil
  app.view_pressed3  = nil
end

local pin_radius_small = 5
local pin_radius_large = 9
local pin_offset_x = pin_radius_small + 4

local function io_takes_pos(view, index)
  local pos_x, pos_y, _, size_y = app.project.viewport:view_bounds(view)
  local sectors = view.frame:takes_count() + 1

  local x = pos_x - pin_offset_x
  local y = pos_y + ((index or 0)/sectors)*size_y
  return x, y
end

local function io_takes_pos_ref(ref)
  local view = rawget(ref, "____view____")
  local prop = rawget(ref, "____prop____")
  local index = view.frame:take_by_id(prop)
  return io_takes_pos(view, index)
end

local function io_gives_pos(view, index)
  local pos_x, pos_y, size_x, size_y = app.project.viewport:view_bounds(view)
  local sectors = view.frame:gives_count() + 1

  local x = pos_x + size_x + pin_offset_x
  local y = pos_y + (index/sectors)*size_y
  return x, y
end

local function io_gives_pos_ref(ref)
  local view = rawget(ref, "____view____")
  local prop = rawget(ref, "____prop____")
  local index = view.frame:give_by_id(prop)
  return io_gives_pos(view, index)
end


local function _pin_gives_at(mx, my)
  local views = app.project.views
  local pin_dx = pin_offset_x - pin_radius_small

  local viewport = app.project.viewport
  for i = 1, #views do
    local view = views[i]
    local pos_x, pos_y, size_x, size_y = viewport:view_bounds(view)

    local dx  = mx - pos_x - size_x - pin_dx
    local dy  = my - pos_y

    if  0 <= dx and dx < 2*pin_radius_large
    and 0 <= dy and dy < size_y then
      for index = 1, view.frame:gives_count() do
        local x, y = io_gives_pos(view, index)
        local dist = math.abs(x - mx) + math.abs(y - my)
        if dist < pin_radius_large then
          return view, index
        end
      end
    end
  end
end

local function _pin_takes_at(mx, my)
  local views = app.project.views
  local pin_dx = pin_offset_x + pin_radius_small

  local viewport = app.project.viewport
  for i = 1, #views do
    local view = views[i]
    local pos_x, pos_y, _, size_y = viewport:view_bounds(view)

    local dx  = mx - pos_x + pin_dx
    local dy  = my - pos_y

    if  0 <= dx and dx < 2*pin_radius_large
    and 0 <= dy and dy < size_y then
      for index = 1, view.frame:takes_count() do
        local x, y = io_takes_pos(view, index)
        local dist = math.abs(x - mx) + math.abs(y - my)
        if dist < pin_radius_large then
          return view, index
        end
      end
    end
  end
end

local function text_width(text)
  return love.graphics.getFont():getWidth(text or "")
end

local function font_height()
  return love.graphics.getFont():getHeight()
end

do
  local os = love.system.getOS()
  if os == "Android"
  or os == "iOS" then
    app.mouse = {
      isDown = function (btn)
        return btn == #love.touch.getTouches()
      end;
    }
  else
    app.mouse = love.mouse
  end
end

function app.pin_color(kind)
  if     kind == EditImageKind   then return 0.95, 0.50, 0.60, 1
  elseif kind == ImageKind       then return 0.80, 0.30, 0.20, 1
  elseif kind == StringKind      then return 0.80, 0.90, 0.20, 1
  elseif kind == NumberKind      then return 0.60, 0.40, 0.90, 1
  elseif kind == Vector4Kind     then return 0.40, 0.20, 0.70, 1
  else                                return 0.75, 0.75, 0.75, 1
  end
end

function app.show_popup(frame, pos_x, pos_y)
  local display_size_x, display_size_y = love.graphics.getDimensions()
  local popup = Popup {
    frame = frame;
    pos_x = pos_x or (display_size_x-frame.size_x)/2;
    pos_y = pos_y or (display_size_y-frame.size_y)/2;
  }
  table.insert(app.popups, popup)
  frame._focus_handler = app.focus_handler
  frame.close = function ()
    remove_once(app.popups, popup)
    app.focus_handler:unassign(frame)
    if app.popup_pressed1 == popup then
      app.popup_pressed1 = nil
    end
    popup.frame = nil
  end
end

function app.keypressed(key, scancode, isrepeat)
  if #app.popups > 0 then
    local top = app.popups[#app.popups]
    try_invoke(top.frame, "keypressed", key, scancode, isrepeat)
    return
  elseif app.global_mode() then
    if key == "s" then
      app.show_connections = not app.show_connections
    elseif key == "space" and app.view_dragged then
      app.project.viewport:set_view_scale(app.view_dragged, 1)
    elseif key == "return" then
      app.project.viewport:set_viewport_scale(1)
    elseif key == "home" then
      app.project.viewport:set_position(0,0)
    end
  elseif key == "menu" then
    local w, h = love.graphics.getDimensions()
    app.open_context_menu(w/2, h/2, nil)
  else
    local has_focus = app.focus_handler:has_focus()
    if has_focus then
      try_invoke(has_focus, "keypressed", key, scancode, isrepeat)
    end
  end
end

function app.keyreleased(key, scancode)
  if #app.popups > 0 then
    local top = app.popups[#app.popups]
    try_invoke(top.frame, "keyreleased", key, scancode)
    return
  elseif app.global_mode() or key == "menu" then
    return
  else
    local has_focus = app.focus_handler:has_focus()
    if has_focus then
      try_invoke(has_focus, "keyreleased", key, scancode)
    end
  end
end

local function is_above(view1, view2)
  local views = app.project.views
  for i = 1, #views do
    local view = views[i]
    if view == view2 then
      return false
    elseif view == view1 then
      return true
    end
  end
  return false
end

function app.mousepressed(mx, my, button)
  local popups = app.popups
  if #popups > 0 then
    local top = popups[#popups]
    local frame = top.frame
    local dx = mx - top.pos_x
    local dy = my - top.pos_y
    if  0 <= dx and dx < frame.size_x
    and 0 <= dy and dy < frame.size_y then
      try_invoke(top.frame, "mousepressed", dx, dy, button)
      if button == MouseButton.LEFT then
        app.popup_pressed1 = top
      end
    else
      try_invoke(top.frame, "globalmousepressed", dx, dy, button)
      if app.focus_handler:has_focus() then
        app.focus_handler:request_focus(nil)
      end
    end
    return
  end

  local view = app.project.viewport:view_at_global_pos(mx, my, app.project.views)

  if app.global_mode() then
    if button == MouseButton.LEFT then
      local pin_view, pin_index = _pin_gives_at(mx, my)
      local pin_above = pin_view and is_above(pin_view, view)
      if pin_above then
        pin_dragged.view  = pin_view
        pin_dragged.index = pin_index
      else
        pin_view, pin_index = _pin_takes_at(mx, my)
        pin_above = pin_view and is_above(pin_view, view)
        if pin_above then
          local from = app.disconnect_raw(pin_view, pin_index)
          if from then
            local from_view = rawget(from, "____view____")
            local from_index = from_view.frame:give_by_id(rawget(from, "____prop____"))
            pin_dragged.view  = from_view
            pin_dragged.index = from_index
          end
        end
      end

      if view and not pin_above then
        app.view_dragged = view
        app.focus_handler:request_focus(view)
        app._push_to_top(app.view_dragged)
      end

    elseif button == MouseButton.RIGHT and view then
      if not view.anchored then
        app.project.viewport:lock_view(view)
      else
        app.project.viewport:unlock_view(view)
      end
    end
    return
  elseif button == MouseButton.RIGHT then
    app.open_context_menu(mx, my, view)
    return
  end

  if button == MouseButton.LEFT   then app.view_pressed1 = view end
  if button == MouseButton.RIGHT  then app.view_pressed2 = view end
  if button == MouseButton.MIDDLE then app.view_pressed3 = view end
  if view then
    local pos_x, pos_y
        , _, _
        , scale = app.project.viewport:view_bounds(view)
    try_invoke(view.frame, "mousepressed", (mx - pos_x)/scale, (my - pos_y)/scale, button)
  end
end

local function compatible(give_kind, take_kind)
  if give_kind == take_kind then return true end
  return give_kind == EditImageKind
     and take_kind == ImageKind
end

function app.mousereleased(mx, my, button)
  if pin_dragged.view then
    local to_view, to_index = _pin_takes_at(mx, my)
    if to_view then
      local from_view = pin_dragged.view

      local give_id, give_kind = from_view.frame:give_by_index(pin_dragged.index)
      local take_id, take_kind = to_view.frame:take_by_index(to_index)

      if compatible(give_kind, take_kind) then
        local from = Ref(from_view, give_id)
        local to   = Ref(to_view, take_id)
        app.connect(from, to)
      end
    end
    pin_dragged.view = nil
    return
  end

  if app.popup_pressed1 then
    local popup = app.popup_pressed1
    local dx = mx - popup.pos_x
    local dy = my - popup.pos_y
    try_invoke(app.popup_pressed1.frame, "mousereleased", dx, dy, button)
    app.popup_pressed1 = nil
    return
  end

  if button == MouseButton.LEFT then
    app.view_dragged = nil
    if app.view_pressed1 then
      local pos_x, pos_y, _, _, scale = app.project.viewport:view_bounds(app.view_pressed1)
      try_invoke(app.view_pressed1.frame, "mousereleased", (mx - pos_x)/scale, (my - pos_y)/scale, button)
    end
    app.view_pressed1 = nil
  elseif button == MouseButton.RIGHT then
    if app.view_pressed2 then
      local pos_x, pos_y, _, _, scale = app.project.viewport:view_bounds(app.view_pressed2)
      try_invoke(app.view_pressed2.frame, "mousereleased", (mx - pos_x)/scale, (my - pos_y)/scale, button)
    end
    app.view_pressed2 = nil
  elseif button == MouseButton.MIDDLE then
    if app.view_pressed3 then
      local pos_x, pos_y, _,_, scale = app.project.viewport:view_bounds(app.view_pressed3)
      try_invoke(app.view_pressed3.frame, "mousereleased", (mx - pos_x)/scale, (my - pos_y)/scale, button)
    end
    app.view_pressed3 = nil
  end
end

function app.mousemoved(mx, my, dx, dy)
  local popups = app.popups
  if #popups > 0 then
    if app.popup_pressed1 then
      local popup = app.popup_pressed1
      local popup_dx = mx - popup.pos_x
      local popup_dy = my - popup.pos_y
      try_invoke(app.popup_pressed1.frame, "mousedragged1", popup_dx, popup_dy, dx, dy)
    else
      local top = popups[#popups]
      local top_dx = mx - top.pos_x
      local top_dy = my - top.pos_y
      local frame = top.frame
      if  0 <= top_dx and top_dx <= frame.size_x
      and 0 <= top_dy and top_dy <= frame.size_y then
        try_invoke(top.frame, "mousemoved", top_dx, top_dy, dx, dy)
      end
    end
    return
  end

  local view = app.project.viewport:view_at_global_pos(mx, my, app.project.views)
  if app.global_mode() then
    local drag = app.view_dragged
    if app.mouse.isDown(MouseButton.MIDDLE) then
      app.project.viewport:pan_viewport(dx, dy)
    elseif drag then
      app.project.viewport:move_view(drag, dx, dy)
    end
  elseif app.view_pressed1 then
    local pos_x, pos_y, _,_, scale = app.project.viewport:view_bounds(app.view_pressed1)
    try_invoke(app.view_pressed1.frame, "mousedragged1", (mx - pos_x)/scale, (my - pos_y)/scale, dx/scale, dy/scale)
  elseif view then
    local pos_x, pos_y, _,_, scale = app.project.viewport:view_bounds(view)
    try_invoke(view.frame, "mousemoved", (mx - pos_x)/scale, (my - pos_y)/scale, dx/scale, dy/scale)
  end
end

function app.wheelmoved(wx, wy)
  local popups = app.popups
  if #popups > 0 then
    local top = popups[#popups]
    try_invoke(top.frame, "wheelmoved", wx, wy)
    return
  end

  if app.view_dragged then
    app.project.viewport:scale_view(app.view_dragged, wy/10)
  else
    app.project.viewport:scale_viewport(wy/10)
  end
end

function app.popup_position()
  local popup = app.popups[#app.popups]
  if not popup then return end
  return popup.pos_x, popup.pos_y
end

function app.global_mode()
  return love.keyboard.isDown("tab")
     and not   alt_is_down()
     and not shift_is_down()
     and not  ctrl_is_down()
end

function app._push_to_top(view)
  if not view then return end
  local views = app.project.views
  remove_once(views, view)
  table.insert(views, 1, view)
end

function app.add_view(index, view)
  local views = app.project.views
  if not view then
    index, view = #views + 1, index
  end
  view = View(view)
  table.insert(views, index, view)
  app.focus_handler:assign(view.frame)
  return view
end

function app.remove_view(view)
  remove_once(app.project.views, view)
  app.focus_handler:unassign(view.frame)

  for to, from in pairs(app.project._links) do
    if to.____view____   == view
    or from.____view____ == view then
      app.disconnect(to)
    end
  end
  view.frame = nil
end

function app.try_create_frame(format, data)
  if format == "image" then
    return PixelFrame {
      data = data;
    };
  elseif format == "text" then
    return TextBufferFrame {
      data = data;
      size_x = 256;
      size_y = 256;
    };
  end
end

function app.open_context_menu(mx, my, view)
  local menu
  if view then
    menu = app.menu.view
    menu.view = view
  else
    menu = app.menu.default
  end
  app.show_popup(menu, menu:_pos(mx, my))
end

function app.update(dt)
  for _, view in ipairs(app.project.views) do
    try_invoke(view.frame, "update", dt)
  end
end

local function draw_link(from_x, from_y, to_x, to_y, kind)
  love.graphics.push()
  if kind then
    local r, g, b = app.pin_color(kind)
    love.graphics.setColor(r, g, b, app.show_connections and 0.8 or 0.4)
  else
    love.graphics.setColor(0.1, 0.7, 0.4, app.show_connections and 0.8 or 0.4)
  end
  love.graphics.setLineWidth(4)
  love.graphics.setLineStyle("smooth")

  local dx = (to_x - from_x)/2
  local bez, x1, y1, x2, y2
  if dx > 0 then
    x1, y1 = from_x + dx, from_y
    x2, y2 = to_x   - dx, to_y
  else
    local dy = (to_y - from_y)/2
    x1, y1 = from_x - dx, from_y + dy*2
    x2, y2 = to_x   + dx, to_y   - dy*2
  end
  bez = love.math.newBezierCurve(from_x, from_y, x1, y1, x2, y2, to_x, to_y)
  love.graphics.line(bez:render())
  bez:release()

  love.graphics.pop()
end

function app.connect(from, to, force)
  local to_view  = rawget(to, "____view____")
  local to_prop  = rawget(to, "____prop____")
  local to_frame = to_view.frame

  if not (to_frame:take_by_id(to_prop) or force) then return end

  app.disconnect_raw(to_view, to_prop)

  local _, a, b, c, d, e, f, g = try_invoke(from, "on_connect")
  try_invoke(to_frame, "on_connect", to_prop, from, a, b, c, d, e, f, g)
  app.project._links[to] = from
end

function app.disconnect(to)
  local view = rawget(to, "____view____")
  local prop = rawget(to, "____prop____")

  app.disconnect_raw(view, prop)
end

function app.disconnect_raw(view, prop)
  local frame = view.frame

  if type(prop) == "number" then
    prop = frame:take_by_index(prop)
  end

  if not prop then return end

  local _links = app.project._links
  for to in pairs(_links) do
    if  rawget(to, "____prop____") == prop
    and rawget(to, "____view____") == view then
      try_invoke(frame, "on_disconnect", prop)
      local from = _links[to]
      _links[to] = nil
      return from
    end
  end
end

local function draw_transparency_pattern(width, height)
  local style = settings.style.transparency or EMPTY
  love.graphics.clear(unpack_color(style.color or default_transparency_color))
  if style.pattern == "checker" then
    love.graphics.setColor(unpack_color(style.color2 or default_checker_color))
    checker_pattern(0, 0, width, height, style.scale or default_checker_scale)
  end
end

local function draw_connectors(view, frame)
  love.graphics.push()
  love.graphics.setLineStyle("smooth")
  love.graphics.setLineWidth(1)

  local clickable = app.global_mode()
  local pin_view, pin_index
  local pin_view2, pin_index2

  if clickable then
    pin_view, pin_index = _pin_gives_at(love.mouse.getPosition())
    pin_view2, pin_index2 = _pin_takes_at(love.mouse.getPosition())
  end

  for index = 1, frame:gives_count() do
    local x, y = io_gives_pos(view, index)
    local _, give_kind = frame:give_by_index(index)
    love.graphics.setColor(app.pin_color(give_kind))
    if  clickable
    and pin_view  == view
    and pin_index == index then
      love.graphics.circle("fill", x, y, pin_radius_large, 4)
    else
      love.graphics.circle("fill", x, y, pin_radius_small, 4)
    end
  end

  for index = 1, frame:takes_count() do
    local x, y = io_takes_pos(view, index)
    local _, takes_kind = frame:take_by_index(index)
    love.graphics.setColor(app.pin_color(takes_kind))
    if  clickable
    and pin_view2  == view
    and pin_index2 == index then
      love.graphics.circle("fill", x, y, pin_radius_large, 4)
    else
      love.graphics.circle("fill", x, y, pin_radius_small, 4)
    end
  end
  love.graphics.pop()
end

function app.textinput(text)
  local has_focus = app.focus_handler:has_focus()
  if has_focus then
    try_invoke(has_focus, "textinput", text)
  end
end

local pad = 2

function app.draw()
  local display_width, display_height = love.graphics.getDimensions()
  local mx, my = love.mouse.getPosition()

  draw_transparency_pattern(display_width, display_height)

  local show_connections = app.global_mode() or app.show_connections
  local show_connectors  = show_connections

  if show_connections then
    for to, from in pairs(app.project._links) do
      local kind = from.kind
      local from_x, from_y = io_gives_pos_ref(from)
      local to_x, to_y = io_takes_pos_ref(to)
      draw_link(from_x, from_y, to_x, to_y, kind)
    end
  end

  -- draw views
  local views    = app.project.views
  local viewport = app.project.viewport
  for i = #views, 1, -1 do
    local view = views[i]
    local frame = view.frame

    if view.anchored then
      love.graphics.setColor(0.5, 0.0, 0.0)
    else
      love.graphics.setColor(0.0, 0.5, 1.0)
    end
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(2*pad)

    local pos_x, pos_y, size_x, size_y, scale = viewport:view_bounds(view)

    local x1, y1 = pos_x - pad, pos_y - pad
    love.graphics.rectangle("line", x1, y1, size_x + 2*pad, size_y + 2*pad)

    local view_id = view:id()
    local w = text_width(view_id)
    local h = font_height()

    love.graphics.rectangle("fill", x1 - pad, y1 - h, w + 2*pad, h)
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.print(view_id, x1, y1 - h)

    if type(frame) == "table" and type(frame.draw) == "function" then
      pleasure.push_region()
      pleasure.translate(pos_x, pos_y)
      love.graphics.setColor(1.0, 1.0, 1.0)
      frame:draw(size_x, size_y, scale, mx - pos_x, my - pos_y) -- NOTE runtime vec2
      pleasure.pop_region()
    end

    if frame.resize then
      if view.anchored then
        love.graphics.setColor(1.0, 0.5, 0.5)
      else
        love.graphics.setColor(0.7, 1.0, 1.0)
      end
      love.graphics.rectangle("fill", pos_x + size_x, pos_y + size_y, 3*pad, 3*pad)
    end

    if show_connectors then
      draw_connectors(view, frame)
    end
  end

  if pin_dragged.view then
    local from_x, from_y = io_gives_pos(pin_dragged.view, pin_dragged.index)
    draw_link(from_x, from_y, mx, my)
  end

  -- draw popups
  local popups = app.popups
  for i = 1, #popups do
    local popup = popups[i]
    local frame = popup.frame

    if type(frame) == "table" and type(frame.draw) == "function" then
      local pos_x = popup.pos_x
      local pos_y = popup.pos_y
      local size_x = frame.size_x
      local size_y = frame.size_y
      pleasure.push_region(pos_x, pos_y)
      love.graphics.setColor(1.0, 1.0, 1.0)
      frame:draw(size_x, size_y, 1, mx - pos_x, my - pos_y)
      pleasure.pop_region()
    end
  end

  -- HACK this should probably not be done on each draw call
  local top = popups[#popups]
  if top then
    app.focus_handler:request_focus(top.frame)
  end
end

return app
