local app                     = require "app"
local vec2                    = require "linear-algebra.Vector2"
local Frame                   = require "Frame"
local IOs                     = require "IOs"
local sandbox                 = require "util.sandbox"
local NumberPacket            = require "packet.Number"
local StringPacket            = require "packet.String"
local try_invoke              = require "pleasure.try".invoke

local LoveFrame = {}
LoveFrame.__index = LoveFrame

LoveFrame._kind = ";LoveFrame;Frame;"

local default_size_x = 640
local default_size_y = 480

setmetatable(LoveFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "LoveFrame constructor must be a table.")
    if not frame.size then
      frame.size = vec2(default_size_x, default_size_y)
    end

    LoveFrame.typecheck(frame, "LoveFrame constructor")

    frame._canvas = love.graphics.newCanvas(default_size_x, default_size_y);

    setmetatable(frame, LoveFrame)

    return frame
  end;
})

LoveFrame.takes = IOs{
  {id = "code", kind = StringPacket};
  {id = "tick", kind = NumberPacket};
}

function LoveFrame:on_connect(prop, from)
  if prop == "code" then
    self.code_in = from
    from:listen(self, self.refresh_code)
    self:refresh_code()
  elseif prop == "tick" then
    self.tick_in = from
    from:listen(self, self.refresh)
    self:refresh()
  end
end

function LoveFrame:on_disconnect(prop)
  if prop == "code" then
    try_invoke(self.code_in, "unlisten", self, self.refresh_code)
    self.code_in   = nil
    self:refresh()
  elseif prop == "tick" then
    try_invoke(self.tick_in, "unlisten", self, self.refresh)
    self.tick_in   = nil
    self:refresh()
  end
end

function LoveFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function LoveFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";LoveFrame;")
end

function LoveFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save
  end
end

function LoveFrame:on_save()
  return self._canvas:newImageData():encode("png")
end

function LoveFrame:refresh()
  local game = self._game
  if not game or type(game.love) ~= "table" then return end
  love.graphics.push("all")
  love.graphics.setCanvas(self._canvas)
  love.graphics.setColor(1, 1, 1)
  love.graphics.clear(0,0,0,0)
  local success, err
  success, err = pcall(game.love.update, 1/60) if not success then print("LoveFrame - update:", err) end
  success, err = pcall(game.love.draw)         if not success then print("LoveFrame - draw:", err) end
  love.graphics.setCanvas()
  love.graphics.pop()
end

function LoveFrame:refresh_code()
  local code = self.code_in
  if not code then return end
  code = code.value
  if not code then return end

  local env, err = sandbox(code, {
    love = {
      keyboard = {
        isDown = function (...)
          return self:has_focus()
             and love.keyboard.isDown(...)
        end;
        isScancodeDown = function (...)
          return self:has_focus()
             and love.keyboard.isScancodeDown(...)
        end;
      };
      mouse = {
        getX = function ()
          local mx = love.mouse.getX()
          local pos, _, scale = app.project.viewport:view_bounds(self._view_)
          return (mx - pos.x)/scale
        end;
        getY = function ()
          local my = love.mouse.getY()
          local pos, _, scale = app.project.viewport:view_bounds(self._view_)
          return (my - pos.y)/scale
        end;
        getPosition = function ()
          local mx, my = love.mouse.getPosition()
          local pos, _, scale = app.project.viewport:view_bounds(self._view_)
          return (mx - pos.x)/scale, (my - pos.y)/scale
        end;
      };
      graphics = {
        getDimensions = function () return self._canvas:getDimensions() end;
        getWidth      = function () return self._canvas:getWidth() end;
        getHeight     = function () return self._canvas:getHeight() end;
        print         = love.graphics.print;
        printf        = love.graphics.printf;
        circle        = love.graphics.circle;
        rectangle     = love.graphics.rectangle;
        setColor      = love.graphics.setColor;
        draw          = love.graphics.draw;
      };
    };
  });

  self._game = env or nil
  if not env then
    print(err)
  end
end

function LoveFrame:draw(_, scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self._canvas, 0, 0, 0, scale, scale)
end

function LoveFrame:invoke_love(event, a, b, c, d, e, f)
  local game_love = self._game     if not game_love then return end
  game_love       = game_love.love if not game_love then return end
  pcall(game_love[event], a, b, c, d, e, f)
end

function LoveFrame:keypressed(key, scancode, isrepeat)
  self:invoke_love("keypressed", key, scancode, isrepeat)
end

function LoveFrame:keyreleased(key, scancode)
  self:invoke_love("keyreleased", key, scancode)
end

function LoveFrame:mousepressed(x, y, button, isTouch)
  self:request_focus()
  self:invoke_love("mousepressed", x, y, button, isTouch)
end

function LoveFrame:mousereleased(x, y, button, isTouch)
  self:invoke_love("mousereleased", x, y, button, isTouch)
end

function LoveFrame:serialize()
  return "LoveFrame {}"
end

return LoveFrame
