do
  local path = ANDROID_DEV
           and "lovely-editor/lib/?.lua;lovely-editor/lib/?/init.lua;lovely-editor/app/?.lua;lovely-editor/app/?/init.lua;"
            or "lib/?.lua;lib/?/init.lua;app/?.lua;app/?/init.lua;"

  package.path = path..package.path
  love.filesystem.setRequirePath(path..love.filesystem.getRequirePath())
end

function string.is (v)
  return type(v) == "string"
end

love.graphics.setDefaultFilter("nearest", "nearest", 0)
love.keyboard.setKeyRepeat(true)

local app                     = require "app"
local vec2                    = require "linear-algebra.Vector2"
local YesNoFrame              = require "frame.YesNo"
local load_data               = require "util.file.load_data"

app.menu.view                 = require "menu.view"
app.menu.default              = require "menu.default"

function love.load()
end

function love.update(dt)
  app.update(dt)
end

function love.keypressed(key, scancode, isrepeat)
  app.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
  app.keyreleased(key, scancode)
end

function love.filedropped(file)
  local data, format = load_data(file)
  if format and data then
    local frame = app.try_create_frame(format, data)
    if frame then
      frame.filename = file:getFilename()
      local mx, my = love.mouse.getPosition()
      local size = frame.size
      local pos_x, pos_y = app.project.viewport:global_to_local_pos(mx - size.x/2, my - size.y/2)

      app.add_view (1, {
        frame = frame;
        pos   = vec2(pos_x, pos_y);
        scale = 1;
      })
    end
  end
end

function love.mousepressed(mx, my, button)
  app.mousepressed(mx, my, button)
end

function love.touchpressed(_, mx, my, _, _, _)
  local button = #love.touch.getTouches()
  if button == 1 then return end

  if button == 5 then
    love.keyboard.setTextInput(not love.keyboard.hasTextInput())
  else
    app.mousepressed(mx, my, button)
  end
end

function love.mousereleased(mx, my, button)
  app.mousereleased(mx, my, button)
end

function love.touchreleased(_, mx, my, _, _, _)
  local button = 1 + #love.touch.getTouches()
  if button == 1 then return end

  app.mousereleased(mx, my, button)
end

function love.mousemoved(mx, my, dx, dy)
  app.mousemoved(mx, my, dx, dy)
end

function love.wheelmoved(wx, wy)
  app.wheelmoved(wx, wy)
end

function love.textinput(text)
  app.textinput(text)
end

function love.draw()
  app.draw()
  love.graphics.origin()
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, 180, 20)
  love.graphics.setColor(1, 0, 1, 0.5)
  love.graphics.print(("FPS: %2d, garbage: %d"):format(love.timer.getFPS(), collectgarbage("count")), 2, 2)
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
      CLOSE = #app.project.views == 0
      if not CLOSE then
        app.show_popup(close_menu)
      end
    end
    return not CLOSE
  end
end
