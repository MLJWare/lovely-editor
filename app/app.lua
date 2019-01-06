local checker_pattern         = require "checker_pattern"
local FocusHandler            = require "FocusHandler"
local ImagePacket             = require "packet.Image"
local StringPacket            = require "packet.String"
local NumberPacket            = require "packet.Number"
local MouseButton             = require "const.MouseButton"
local PixelFrame              = require "frame.Pixel"
local pleasure                = require "pleasure"
local Popup                   = require "Popup"
local Ref                     = require "Ref"
local remove_once             = require "util.list.remove_once"
local TextBufferFrame         = require "frame.TextBuffer"
local vec2                    = require "linear-algebra.Vector2"
local View                    = require "View"
local Viewport                = require "Viewport"

local shift_is_down           = require "util.shift_is_down"
local  ctrl_is_down           = require "util.ctrl_is_down"
local   alt_is_down           = require "util.alt_is_down"

local try_invoke              = pleasure.try.invoke

local pin_dragged = {
  view = nil;
  index = -1;
}

local EMPTY = {}
local global_style = {
  transparency = {
    pattern = "checker";
    color  = {0.15, 0.15, 0.15};
    color2 = {0.05, 0.05, 0.05};
    scale  = 32;
  };
}

local default_checker_color      = {0.8, 0.8, 0.8}
local default_transparency_color = {0.6, 0.6, 0.6}
local default_checker_scale      = 8

local app = {
  viewport = Viewport {
    pos    = vec2(0, 0);
    scale  = 1;
  };
  views  = {};
  popups = {};
  _links = {};

  menu   = {};

  focus_handler = FocusHandler ();

  show_connections = true;


  view_dragged   = nil;
  view_pressed1  = nil;
  view_pressed2  = nil;
  view_pressed3  = nil;
  popup_pressed1 = nil;
}

local _delta_ = vec2(0)


local pin_radius_small = 5
local pin_radius_large = 9
local pin_offset_x = pin_radius_small + 4

local function _io_takes_pos(view, index)
  local pos, size = app.viewport:view_bounds(view)
  local sectors = view.frame:takes_count() + 1

  local x = pos.x - pin_offset_x
  local y = pos.y + (index/sectors)*size.y
  return x, y
end

local function io_takes_pos(ref)
  local view = rawget(ref, "____view____")
  local prop = rawget(ref, "____prop____")
  local index = view.frame:take_by_id(prop)
  return vec2(_io_takes_pos(view, index))
end

local function _io_gives_pos(view, index)
  local pos, size = app.viewport:view_bounds(view)
  local gives = view.frame.gives
  local sectors = #gives + 1

  local x = pos.x + size.x + pin_offset_x
  local y = pos.y + (index/sectors)*size.y
  return x, y
end

local function io_gives_pos(ref)
  local view = rawget(ref, "____view____")
  local prop = rawget(ref, "____prop____")
  local gives = view.frame.gives
  local index = gives[prop]
  return vec2(_io_gives_pos(view, index))
end

local function _pin_gives_at(mx, my)
  local views = app.views
  local pin_dx = pin_offset_x - pin_radius_small

  for i = 1, #views do
    local view = views[i]
    local pos, size = app.viewport:view_bounds(view)

    local dx  = mx - pos.x - size.x - pin_dx
    local dy  = my - pos.y

    if  0 <= dx and dx < 2*pin_radius_large
    and 0 <= dy and dy < size.y then
      for index = 1, #(view.frame.gives or EMPTY) do
        local x, y = _io_gives_pos(view, index)
        local dist = math.abs(x - mx) + math.abs(y - my)
        if dist < pin_radius_large then
          return view, index
        end
      end
    end
  end
end

local function _pin_takes_at(mx, my)
  local views = app.views
  local pin_dx = pin_offset_x + pin_radius_small

  for i = 1, #views do
    local view = views[i]
    local pos, size = app.viewport:view_bounds(view)

    local dx  = mx - pos.x + pin_dx
    local dy  = my - pos.y

    if  0 <= dx and dx < 2*pin_radius_large
    and 0 <= dy and dy < size.y then
      local frame = view.frame
      for index = 1, frame:takes_count() do
        local x, y = _io_takes_pos(view, index)
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
  if     kind == StringPacket  then return 0.80, 0.90, 0.20, 1
  elseif kind == ImagePacket   then return 0.80, 0.30, 0.20, 1
  elseif kind == NumberPacket  then return 0.40, 0.30, 0.70, 11
  else                              return 0.75, 0.75, 0.75, 1
  end
end

function app.show_popup(frame, pos)
  local popup = Popup {
    frame = frame;
    pos   = pos or vec2(love.graphics.getDimensions()):subv(frame.size):divn(2);
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
      app.viewport:set_view_scale(app.view_dragged, 1)
    elseif key == "return" then
      app.viewport:set_viewport_scale(1)
    elseif key == "home" then
      app.viewport:set_position(0,0)
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

local function is_above(view1, view2)
  local views = app.views
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
    _delta_:setn(mx, my):subv(top.pos)
    if 0 <= _delta_ and _delta_ < top.frame.size then
      try_invoke(top.frame, "mousepressed", _delta_.x, _delta_.y, button)
      if button == MouseButton.LEFT then
        app.popup_pressed1 = top
      end
    else
      try_invoke(top.frame, "globalmousepressed", _delta_.x, _delta_.y, button)
      if app.focus_handler:has_focus() then
        app.focus_handler:request_focus(nil)
      end
    end
    return
  end

  local view = app.viewport:view_at_global_pos(vec2(mx, my), app.views)

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
            local gives = from_view.frame.gives
            local from_index = gives[rawget(from, "____prop____")]
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
        app.viewport:lock_view(view)
      else
        app.viewport:unlock_view(view)
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
    local pos, _, scale = app.viewport:view_bounds(view)
    try_invoke(view.frame, "mousepressed", (mx - pos.x)/scale, (my - pos.y)/scale, button)
  end
end


local function compatible(give_kind, take_kind)
  return give_kind == take_kind
end

function app.mousereleased(mx, my, button)
  if pin_dragged.view then
    local to_view, to_index = _pin_takes_at(mx, my)
    if to_view then
      local from_view = pin_dragged.view

      local give = from_view.frame.gives[pin_dragged.index]
      local take_id, take_kind = to_view.frame:take_by_index(to_index)

      if compatible(give.kind, take_kind) then
        local from = Ref(from_view, give.id)
        local to   = Ref(to_view, take_id)
        app.connect(from, to)
      end
    end
    pin_dragged.view = nil
    return
  end

  if app.popup_pressed1 then
    _delta_:setn(mx, my):subv(app.popup_pressed1.pos)
    try_invoke(app.popup_pressed1.frame, "mousereleased", _delta_.x, _delta_.y, button)
    app.popup_pressed1 = nil
    return
  end

  if button == MouseButton.LEFT then
    app.view_dragged = nil
    if app.view_pressed1 then
      local pos, _, scale = app.viewport:view_bounds(app.view_pressed1)
      try_invoke(app.view_pressed1.frame, "mousereleased", (mx - pos.x)/scale, (my - pos.y)/scale, button)
    end
    app.view_pressed1 = nil
  elseif button == MouseButton.RIGHT then
    if app.view_pressed2 then
      local pos, _, scale = app.viewport:view_bounds(app.view_pressed2)
      try_invoke(app.view_pressed2.frame, "mousereleased", (mx - pos.x)/scale, (my - pos.y)/scale, button)
    end
    app.view_pressed2 = nil
  elseif button == MouseButton.MIDDLE then
    if app.view_pressed3 then
      local pos, _, scale = app.viewport:view_bounds(app.view_pressed3)
      try_invoke(app.view_pressed3.frame, "mousereleased", (mx - pos.x)/scale, (my - pos.y)/scale, button)
    end
    app.view_pressed3 = nil
  end
end

function app.mousemoved(mx, my, dx, dy)
  local popups = app.popups
  if #popups > 0 then
    if app.popup_pressed1 then
      _delta_:setn(mx, my):subv(app.popup_pressed1.pos)
      try_invoke(app.popup_pressed1.frame, "mousedragged1", _delta_.x, _delta_.y, dx, dy)
    else
      local top = popups[#popups]
      _delta_:setn(mx, my):subv(top.pos)
      if 0 <= _delta_ and _delta_ <= top.frame.size then
        try_invoke(top.frame, "mousemoved", _delta_.x, _delta_.y, dx, dy)
      end
    end
    return
  end

  local view = app.viewport:view_at_global_pos(vec2(mx, my), app.views)
  if app.global_mode() then
    local delta = vec2(dx, dy)
    local drag = app.view_dragged
    if app.mouse.isDown(MouseButton.MIDDLE) then
      app.viewport:pan_viewport(delta)
    elseif drag then
      app.viewport:move_view(drag, delta)
    end
  elseif app.view_pressed1 then
    local pos, _, scale = app.viewport:view_bounds(app.view_pressed1)
    try_invoke(app.view_pressed1.frame, "mousedragged1", (mx - pos.x)/scale, (my - pos.y)/scale, dx/scale, dy/scale)
  elseif view then
    local pos, _, scale = app.viewport:view_bounds(view)
    try_invoke(view.frame, "mousemoved", (mx - pos.x)/scale, (my - pos.y)/scale, dx/scale, dy/scale)
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
    app.viewport:scale_view(app.view_dragged, wy/10)
  else
    app.viewport:scale_viewport(wy/10)
  end
end

function app.popup_position()
  local popup = app.popups[#app.popups]
  return popup and popup.pos:copy()
end

function app.global_mode()
  return love.keyboard.isDown("tab")
     and not   alt_is_down()
     and not shift_is_down()
     and not  ctrl_is_down()
end

function app._push_to_top(view)
  if not view then return end
  remove_once(app.views, view)
  table.insert(app.views, 1, view)
end

function app.add_view(index, view)
  if not view then
    index, view = #app.views + 1, index
  end
  view = View(view)
  table.insert(app.views, index, view)
  view.frame._focus_handler = app.focus_handler
  return view
end

function app.remove_view(view)
  remove_once(app.views, view)
  app.focus_handler:unassign(view.frame)

  for to, from in pairs(app._links) do
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
      size = vec2(256, 256);
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
  for _, view in ipairs(app.views) do
    try_invoke(view.frame, "update", dt)
  end
end



local function draw_link(from, to)
  love.graphics.push()
  love.graphics.setColor(0.1, 0.7, 0.4, app.show_connections and 1 or 0.5)
  love.graphics.setLineWidth(4)
  love.graphics.setLineStyle("smooth")

  local dx = (to.x - from.x)/2
  local bez, x1, y1, x2, y2
  if dx > 0 then
    x1, y1 = from.x + dx, from.y
    x2, y2 = to.x   - dx, to.y
  else
    local dy = (to.y - from.y)/2
    x1, y1 = from.x - dx, from.y + dy*2
    x2, y2 = to.x   + dx, to.y   - dy*2
  end
  bez = love.math.newBezierCurve(from.x, from.y, x1, y1, x2, y2, to.x, to.y)
  love.graphics.line(bez:render())
  bez:release()

  love.graphics.pop()
end

local pad = 2

function app.connect(from, to)
  local frame = rawget(to, "____view____").frame
  local prop  = rawget(to, "____prop____")

  if not frame:take_by_id(prop) then return end

  app.disconnect_raw(
    rawget(to, "____view____"),
    rawget(to, "____prop____"))

  try_invoke(frame, "on_connect", prop, from)
  app._links[to] = from
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

  for to in pairs(app._links) do
    if  rawget(to, "____prop____") == prop
    and rawget(to, "____view____") == view then
      try_invoke(frame, "on_disconnect", prop)
      local from = app._links[to]
      app._links[to] = nil
      return from
    end
  end
end

local function draw_transparency_pattern(width, height)
  local style = global_style.transparency or EMPTY
  love.graphics.clear(style.color or default_transparency_color)
  if style.pattern == "checker" then
    love.graphics.setColor(style.color2 or default_checker_color)
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

  local gives = frame.gives
  for index = 1, #(gives or EMPTY) do
    local x, y = _io_gives_pos(view, index)
    love.graphics.setColor(app.pin_color(gives[index].kind))
    if  clickable
    and pin_view  == view
    and pin_index == index then
      love.graphics.circle("fill", x, y, pin_radius_large, 4)
    else
      love.graphics.circle("fill", x, y, pin_radius_small, 4)
    end
  end

  for index = 1, frame:takes_count() do
    local x, y = _io_takes_pos(view, index)
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

function app.draw()
  local display_width, display_height = love.graphics.getDimensions()
  local mx, my = love.mouse.getPosition()

  draw_transparency_pattern(display_width, display_height)

  local show_connections = app.global_mode() or app.show_connections
  local show_connectors  = show_connections

  if show_connections then
    for to, from in pairs(app._links) do
      draw_link(io_gives_pos(from), io_takes_pos(to))
    end
  end

  -- draw views
  local views = app.views
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

    local pos, size, scale = app.viewport:view_bounds(view)

    local x1, y1 = pos.x - pad, pos.y - pad
    love.graphics.rectangle("line", x1, y1, size.x + 2*pad, size.y + 2*pad)

    local frame_id = frame:id()
    local w = text_width(frame_id)
    local h = font_height()

    love.graphics.rectangle("fill", x1 - pad, y1 - h, w + 2*pad, h)
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.print(frame_id, x1, y1 - h)

    if type(frame) == "table" and type(frame.draw) == "function" then
      pleasure.push_region()
      pleasure.translate(pos.x, pos.y)
      love.graphics.setColor(1.0, 1.0, 1.0)
      frame:draw(size, scale, mx - pos.x, my - pos.y)
      pleasure.pop_region()
    end

    if frame.resize then
      if view.anchored then
        love.graphics.setColor(1.0, 0.5, 0.5)
      else
        love.graphics.setColor(0.7, 1.0, 1.0)
      end
      love.graphics.rectangle("fill", pos.x + size.x, pos.y + size.y, 3*pad, 3*pad)
    end

    if show_connectors then
      draw_connectors(view, frame)
    end
  end

  if pin_dragged.view then
    draw_link(vec2(_io_gives_pos(pin_dragged.view, pin_dragged.index)), vec2(mx, my))
  end

  -- draw popups
  local popups = app.popups
  for i = 1, #popups do
    local popup = popups[i]
    local frame = popup.frame

    if type(frame) == "table" and type(frame.draw) == "function" then
      local pos  = popup.pos
      local size = frame.size
      pleasure.push_region(pos.x, pos.y)
      love.graphics.setColor(1.0, 1.0, 1.0)
      frame:draw(size, 1, mx - pos.x, my - pos.y)
      pleasure.pop_region()
    end
  end

  -- HACK this should probably not be done on each draw call
  local top = popups[#popups]
  if top then
    app.focus_handler:request_focus(top.frame)
  end
end


for _, view in ipairs(app.views) do
  app.focus_handler:assign(view.frame)
end

return app