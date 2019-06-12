local app                     = require "app"
local Frame                   = require "Frame"
local IOs                     = require "IOs"
local sandbox                 = require "util.sandbox"
local NumberKind              = require "Kind.Number"
local StringKind              = require "Kind.String"
local try_invoke              = require ("pleasure.try").invoke

local LoveFrame = {}
LoveFrame.__index = LoveFrame

LoveFrame._kind = ";LoveFrame;Frame;"

local default_size_x = 640
local default_size_y = 480

setmetatable(LoveFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "LoveFrame constructor must be a table.")
    frame.size_x = frame.size_x or default_size_x
    frame.size_y = frame.size_y or default_size_y

    LoveFrame.typecheck(frame, "LoveFrame constructor")

    frame._canvas = love.graphics.newCanvas(default_size_x, default_size_y);

    setmetatable(frame, LoveFrame)

    return frame
  end;
})

LoveFrame.takes = IOs{
  {id = "signal_code", kind = StringKind};
  {id = "signal_tick", kind = NumberKind};
}

function LoveFrame:on_connect(prop, from, data)
  if prop == "signal_code" then
    self.signal_code = from
    from:listen(self, prop, self.refresh_code)
    self:refresh_code(prop, data)
  elseif prop == "signal_tick" then
    self.signal_tick = from
    from:listen(self, prop, self.refresh_tick)
    self:refresh_tick(prop, data)
  end
end

function LoveFrame:on_disconnect(prop)
  if prop == "signal_code" then
    try_invoke(self.signal_code, "unlisten", self, prop, self.refresh_code)
    self.signal_code = nil
    self:refresh_code(prop, nil)
  elseif prop == "signal_tick" then
    try_invoke(self.signal_tick, "unlisten", self, prop, self.refresh_tick)
    self.signal_tick = nil
    self:refresh_tick(prop, nil)
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
  local data = self._canvas:newImageData()
  local result = data:encode("png")
  data:release()
  return result
end

function LoveFrame:refresh_tick()
  local game = self._game
  if not game then return end
  local game_love = game.love
  if type(game_love) ~= "table" then return end
  love.graphics.push("all")
  love.graphics.setCanvas(self._canvas)
  love.graphics.setColor(1, 1, 1)
  love.graphics.clear(0,0,0,0)
  local game_update = game_love.update
  if game_update then
    local success, err = pcall(game_update, 1/60)
    if not success then print("LoveFrame - update:", err) end
  end
  local game_draw   = game_love.draw
  if game_draw then
    local success, err = pcall(game_draw)
    if not success then print("LoveFrame - draw:", err) end
  end
  love.graphics.setCanvas()
  love.graphics.pop()
end

function LoveFrame:refresh_code(_, code)
  if not code then return end

  local env, err = sandbox(code, {
    math = {
      abs = math.abs;
      asin = math.asin;
      acos = math.acos;
      atan = math.atan;
      atan2 = math.atan2;
      ceil = math.ceil;
      cos = math.cos;
      cosh = math.cosh;
      deg = math.deg;
      exp = math.exp;
      floor = math.floor;
      huge = math.huge;
      sin = math.sin;
      tan = math.tan;
    };
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
          local pos_x, _
              , _, _
              , scale = app.project.viewport:view_bounds(self._view_)
          return (mx - pos_x)/scale
        end;
        getY = function ()
          local my = love.mouse.getY()
          local _, pos_y
              , _, _
              , scale = app.project.viewport:view_bounds(self._view_)
          return (my - pos_y)/scale
        end;
        getPosition = function ()
          local mx, my = love.mouse.getPosition()
          local pos_x, pos_y
              , _, _
              , scale = app.project.viewport:view_bounds(self._view_)
          return (mx - pos_x)/scale, (my - pos_y)/scale
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

function LoveFrame:draw(_, _, scale)
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

function LoveFrame.serialize()
  return "LoveFrame {}"
end

function LoveFrame.id(_)
  return "Love"
end

return LoveFrame
