package.path = "lib/?.lua;lib/?/init.lua;app/?.lua;app/?/init.lua;"..package.path

function string.is (v)
  return type(v) == "string"
end

love.graphics.setDefaultFilter("nearest", "nearest", 0)
love.keyboard.setKeyRepeat(true)

local app                     = require "app"
local ctrl_is_down            = require "util.ctrl_is_down"
local shift_is_down           = require "util.shift_is_down"
local vec2                    = require "linear-algebra.Vector2"
local pleasure                = require "pleasure"
local View                    = require "View"
local Popup                   = require "Popup"
local Ref                     = require "Ref"
local PixelFrame              = require "frame.Pixel"
local YesNoFrame              = require "frame.YesNo"
local TextFrame               = require "frame.Text"
local ImagePacket             = require "packet.Image"
local MouseButton             = require "const.MouseButton"
local checker_pattern         = require "checker_pattern"
local FocusHandler            = require "FocusHandler"
local load_image_data         = require "util.file.load_image_data"
local remove_once             = require "util.list.remove_once"
local try_invoke              = pleasure.try.invoke

local view_menu               = require "frame.menu.view"
local default_menu            = require "frame.menu.default"

local pin_dragged = {
  view = nil;
  index = -1;
}

local EMPTY = {}

local global_show_connections = true

local focus_handler  = FocusHandler ()
local  view_dragged  = nil
local  view_pressed1 = nil
local  view_pressed2 = nil
local  view_pressed3 = nil
local popup_pressed1 = nil

local function global_mode()
  return    shift_is_down()
     and not ctrl_is_down()
end

local _delta_ = vec2(0)

local popups = {}

function love.load()
  app.add_view (1, {
    frame = PixelFrame {
      data = love.image.newImageData(64, 64);
    };
    pos   = vec2(100, 200);
    scale = 1;
  })

  app.add_view (1, {
    frame = PixelFrame {
      data = love.image.newImageData(64, 64);
    };
    pos   = vec2(300, 300);
    scale = 1;
  })

  app.add_view (1, {
    frame = TextFrame {
      text = [[
vec4 effect(vec4 color, Image texture, vec2 tex_pos, vec2 screen_coords)
{
  vec4 pixel = Texel(texture, tex_pos);
  return vec4(1 - pixel.rgb, pixel.a);
}]];
      size = vec2(128, 128);
    };
    pos   = vec2(400, 100);
    scale = 1;
  })
end

function app.show_popup(frame, pos)
  local popup = Popup{
    frame = frame;
    pos   = pos or vec2(love.graphics.getDimensions()):subv(frame.size):divn(2);
  }
  table.insert(popups, popup)
  frame._focus_handler = focus_handler
  frame.close = function ()
    remove_once(popups, popup)
    if popup_pressed1 == popup then
      popup_pressed1 = nil
    end
  end
end

function app.popup_position()
  local popup = popups[#popups]
  return popup and popup.pos:copy()
end

focus_handler:assign_list(app.views)

function love.keypressed(key, scancode, isrepeat)
  if #popups > 0 then
    local top = popups[#popups]
    try_invoke(top.frame, "keypressed", key, scancode, isrepeat)
    return
  elseif global_mode() then
    if key == "tab" then
      global_show_connections = not global_show_connections
    elseif key == "space" and view_dragged then
      app.viewport:set_view_scale(view_dragged, 1)
    elseif key == "return" then
      app.viewport:set_viewport_scale(1)
    elseif key == "home" then
      app.viewport:set_position(0,0)
    end
  else
    local has_focus = focus_handler:has_focus()
    if has_focus then
      try_invoke(has_focus.frame, "keypressed", key, scancode, isrepeat)
    end
  end
end

local function push_to_top(view)
  if not view then return end
  remove_once(app.views, view)
  table.insert(app.views, 1, view)
end

function app.add_view(index, view)
  if not view then
    index, view = #app.views, index
  end
  view = View(view)
  table.insert(app.views, index, view)
  view._focus_handler = focus_handler
  return view
end

function app.remove_view(view)
  remove_once(app.views, view)
  view._focus_handler = nil
end


local function open_context_menu(mx, my, view)
  local menu
  if view then
    menu = view_menu
    menu.view = view
  else
    menu = default_menu
  end
  app.show_popup(menu, menu:_pos(mx, my))
end

local function text_width(text)
  return love.graphics.getFont():getWidth(text or "")
end

local function font_height()
  return love.graphics.getFont():getHeight()
end

function love.filedropped(file)
  local data = load_image_data(file)
  if data then
    local mx, my = love.mouse.getPosition()
    local width, height = data:getDimensions()
    app.add_view(1, {
      frame = PixelFrame{
        data = data;
      };
      pos   = app.viewport:global_to_local_pos(vec2(mx - width/2, my - height/2));
      scale = 1;
    })
  end
end

local pin_radius_small = 5
local pin_radius_large = 9
local pin_offset_x = pin_radius_small + 4

local function _io_takes_pos(view, index)
  local pos, size = app.viewport:view_bounds(view)
  local takes = view.frame.takes
  local sectors = #takes + 1

  local x = pos.x - pin_offset_x
  local y = pos.y + (index/sectors)*size.y
  return x, y
end

local function io_takes_pos(ref)
  local view = rawget(ref, "____view____")
  local prop = rawget(ref, "____prop____")
  local takes = view.frame.takes
  local index = takes[prop]
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
      for index = 1, #(view.frame.takes or EMPTY) do
        local x, y = _io_takes_pos(view, index)
        local dist = math.abs(x - mx) + math.abs(y - my)
        if dist < pin_radius_large then
          return view, index
        end
      end
    end
  end
end

function love.mousepressed(mx, my, button)
  if #popups > 0 then
    local top = popups[#popups]
    _delta_:setn(mx, my):subv(top.pos)
    if 0 <= _delta_ and _delta_ < top.frame.size then
      try_invoke(top.frame, "mousepressed", _delta_.x, _delta_.y, button)
      if button == MouseButton.LEFT then
        popup_pressed1 = top
      end
    else
      try_invoke(top.frame, "globalmousepressed", _delta_.x, _delta_.y, button)
      if focus_handler:has_focus() then
        focus_handler:request_focus(nil)
      end
    end
    return
  end

  local view = app.viewport:view_at_global_pos(vec2(mx, my), app.views)
  focus_handler:request_focus(view)

  if global_mode() then
    if button == 1 then
      view_dragged = view
      push_to_top(view_dragged)

      if not view then
        local pin_view, pin_index = _pin_gives_at(mx, my)
        pin_dragged.view  = pin_view
        pin_dragged.index = pin_index

        if not pin_view then
          pin_view, pin_index = _pin_takes_at(mx, my)
          if pin_view then
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
      end
    elseif button == 2 and view then
      if not view.anchored then
        app.viewport:lock_view(view)
      else
        app.viewport:unlock_view(view)
      end
    end
    return
  elseif button == MouseButton.RIGHT then
    open_context_menu(mx, my, view)
    return
  end

  if button == MouseButton.LEFT   then view_pressed1 = view end
  if button == MouseButton.RIGHT  then view_pressed2 = view end
  if button == MouseButton.MIDDLE then view_pressed3 = view end
  if view then
    local pos, _, scale = app.viewport:view_bounds(view)
    try_invoke(view.frame, "mousepressed", (mx - pos.x)/scale, (my - pos.y)/scale, button)
  end
end

local function compatible(give_kind, take_kind)
  return give_kind == take_kind
end

function love.mousereleased(mx, my, button)
  if pin_dragged.view then
    local to_view, to_index = _pin_takes_at(mx, my)
    if to_view then
      local from_view = pin_dragged.view

      local give = from_view.frame.gives[pin_dragged.index]
      local take =   to_view.frame.takes[to_index]

      if compatible(give.kind, take.kind) then
        local from = Ref(from_view, give.id)
        local to   = Ref(to_view, take.id)
        app.connect(from, to)
      end
    end
    pin_dragged.view = nil
    return
  end

  if popup_pressed1 then
    _delta_:setn(mx, my):subv(popup_pressed1.pos)
    try_invoke(popup_pressed1.frame, "mousereleased", _delta_.x, _delta_.y, button)
    popup_pressed1 = nil
    return
  end

  if button == 1 then
    view_dragged = nil
    if view_pressed1 then
      local pos, _, scale = app.viewport:view_bounds(view_pressed1)
      try_invoke(view_pressed1.frame, "mousereleased", (mx - pos.x)/scale, (my - pos.y)/scale, button)
    end
    view_pressed1 = nil
  elseif button == 2 then
    if view_pressed2 then
      local pos, _, scale = app.viewport:view_bounds(view_pressed2)
      try_invoke(view_pressed2.frame, "mousereleased", (mx - pos.x)/scale, (my - pos.y)/scale, button)
    end
    view_pressed2 = nil
  elseif button == 3 then
    if view_pressed3 then
      local pos, _, scale = app.viewport:view_bounds(view_pressed3)
      try_invoke(view_pressed3.frame, "mousereleased", (mx - pos.x)/scale, (my - pos.y)/scale, button)
    end
    view_pressed3 = nil
  end
end

local function bypass_drag()
  return love.keyboard.isDown("lalt", "ralt")
end

function love.mousemoved(mx, my, dx, dy)
  if #popups > 0 then
    if popup_pressed1 then
      _delta_:setn(mx, my):subv(popup_pressed1.pos)
      try_invoke(popup_pressed1.frame, "mousedragged1", _delta_.x, _delta_.y, dx, dy)
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
  if global_mode() then
    local delta = vec2(dx, dy)
    local drag = view_dragged
    if love.mouse.isDown(3) then
      app.viewport:pan_viewport(delta)
    elseif drag then
      app.viewport:move_view(drag, delta)
    end
  elseif view_pressed1 and not bypass_drag() then
    local pos, _, scale = app.viewport:view_bounds(view_pressed1)
    try_invoke(view_pressed1.frame, "mousedragged1", (mx - pos.x)/scale, (my - pos.y)/scale, dx/scale, dy/scale)
  elseif view then
    local pos, _, scale = app.viewport:view_bounds(view)
    try_invoke(view.frame, "mousemoved", (mx - pos.x)/scale, (my - pos.y)/scale, dx/scale, dy/scale)
  end
end

function love.wheelmoved(wx, wy)
  if #popups > 0 then
    local top = popups[#popups]
    try_invoke(top.frame, "wheelmoved", wx, wy)
    return
  end

  if view_dragged then
    app.viewport:scale_view(view_dragged, wy/10)
  else
    app.viewport:scale_viewport(wy/10)
  end
end

function love.textinput(text)
  if #popups > 0 then
    local top = popups[#popups]
    try_invoke(top.frame, "textinput", text)
    return
  end
  --TODO delegate to views
end


local function draw_link(from, to)
  love.graphics.push()
  love.graphics.setColor(0.1, 0.7, 0.4, global_show_connections and 1 or 0.5)
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

local _links = {}

function app.connect(from, to)
  local frame = rawget(to, "____view____").frame
  local prop  = rawget(to, "____prop____")

  if not frame.takes[prop] then return end

  app.disconnect_raw(
    rawget(to, "____view____"),
    rawget(to, "____prop____"))

  try_invoke(frame, "on_connect", prop, from)
  _links[to] = from
end

function app.disconnect(to)
  local view = rawget(to, "____view____")
  local prop = rawget(to, "____prop____")

  app.disconnect_raw(view, prop)
end

function app.disconnect_raw(view, prop)
  local frame = view.frame
  local takes = frame.takes

  if not takes then return end

  if type(prop) == "number" then
    prop = takes[prop].id
  end

  if not (prop and takes[prop]) then return end

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

local global_style = {
  transparency = {
    pattern = "checker";
    color  = {0.05, 0.05, 0.05};
    color2 = {0.15, 0.15, 0.15};
    scale  = 8;
  };
}

local default_checker_color      = {0.8, 0.8, 0.8}
local default_transparency_color = {0.6, 0.6, 0.6}
local default_checker_scale      = 8

local function draw_transparency_pattern(width, height)
  local style = global_style.transparency or EMPTY
  love.graphics.clear(style.color or default_transparency_color)
  if style.pattern == "checker" then
    love.graphics.setColor(style.color2 or default_checker_color)
    checker_pattern(0, 0, width, height, style.scale or default_checker_scale)
  end
end

local function pin_color(kind)
  if kind == string          then return 0.80, 0.90, 0.20, 1
  elseif kind == ImagePacket then return 0.80, 0.30, 0.20, 1
  else                            return 0.75, 0.75, 0.75, 1
  end
end

local function draw_connectors(view, frame)
  love.graphics.push()
  love.graphics.setLineStyle("smooth")
  love.graphics.setLineWidth(1)

  local clickable = global_mode()
  local pin_view, pin_index
  local pin_view2, pin_index2

  if clickable then
    pin_view, pin_index = _pin_gives_at(love.mouse.getPosition())
    pin_view2, pin_index2 = _pin_takes_at(love.mouse.getPosition())
  end

  local gives = frame.gives
  for index = 1, #(gives or EMPTY) do
    local x, y = _io_gives_pos(view, index)
    love.graphics.setColor(pin_color(gives[index].kind))
    if  clickable
    and pin_view  == view
    and pin_index == index then
      love.graphics.circle("fill", x, y, pin_radius_large, 4)
    else
      love.graphics.circle("fill", x, y, pin_radius_small, 4)
    end
  end

  local takes = frame.takes
  for index = 1, #(takes or EMPTY) do
    local x, y = _io_takes_pos(view, index)
    love.graphics.setColor(pin_color(takes[index].kind))
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

function love.draw()
  love.window.setTitle(love.timer.getFPS())

  local display_width, display_height = love.graphics.getDimensions()
  local mx, my = love.mouse.getPosition()

  draw_transparency_pattern(display_width, display_height)

  local show_connections = global_mode() or global_show_connections
  local show_connectors  = show_connections

  if show_connections then
    for to, from in pairs(_links) do
      draw_link(io_gives_pos(from), io_takes_pos(to))
    end
  end

  -- draw views
  local views = app.views
  for i = #views, 1, -1 do
    local view = views[i]
    local frame = view.frame

    if view.anchored then
      love.graphics.setColor(0.5,0,0)
    else
      love.graphics.setColor(0, 0.5, 1)
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
    love.graphics.setColor(1,1,1)
    love.graphics.print(frame_id, x1, y1 - h)

    if type(frame) == "table" and type(frame.draw) == "function" then
      pleasure.push_region()
      pleasure.translate(pos.x, pos.y)
      love.graphics.setColor(1, 1, 1)
      frame:draw(size, scale, mx - pos.x, my - pos.y)
      pleasure.pop_region()
    end

    if show_connectors then
      draw_connectors(view, frame)
    end
  end

  if pin_dragged.view then
    draw_link(vec2(_io_gives_pos(pin_dragged.view, pin_dragged.index)), vec2(mx, my))
  end

  -- draw popups
  for i = 1, #popups do
    local popup = popups[i]
    local frame = popup.frame

    if type(frame) == "table" and type(frame.draw) == "function" then
      local pos  = popup.pos
      local size = frame.size
      pleasure.push_region(pos.x, pos.y)
      love.graphics.setColor(1, 1, 1)
      frame:draw(size, 1, mx - pos.x, my - pos.y)
      pleasure.pop_region()
    end
  end

  -- HACK this should probably not be done on each draw call
  local top = popups[#popups]
  if top then
    focus_handler:request_focus(top.frame)
  end
end

do
  local CLOSE = nil
  local close_menu = YesNoFrame{
    title = "Close?";
    text  = "Are you sure you want to close the editor?";
    option_yes = function ()
      CLOSE = true
      love.event.quit()
    end;
    option_no  = function ()
      CLOSE = nil
    end;
  }
  function love.quit()
    if CLOSE == nil then
      app.show_popup(close_menu)
      CLOSE = false
    end
    return not CLOSE
  end
end