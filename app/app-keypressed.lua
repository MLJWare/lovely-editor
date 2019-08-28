local app                     = require "app"

local save_project            = require "dialog.save_project"

local shift_is_down           = require "util.shift_is_down"
local  ctrl_is_down           = require "util.ctrl_is_down"
local   alt_is_down           = require "util.alt_is_down"

local try                     = require "pleasure.try"
local try_invoke = try.invoke

function app.keypressed(key, scancode, isrepeat)
  if #app.popups > 0 then
    local top = app.popups[#app.popups]
    try_invoke(top.frame, "keypressed", key, scancode, isrepeat)
    return
  elseif app.global_mode() then
    if key == "s" then
      local project = app.project
      project.show_connections = not project.show_connections
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
  elseif key == "s"
  and ctrl_is_down()
  and alt_is_down()
  and not shift_is_down() then
    app.show_popup(save_project)
  else
    local has_focus = app.focus_handler:has_focus()
    if has_focus then
      try_invoke(has_focus, "keypressed", key, scancode, isrepeat)
    end
  end
end
