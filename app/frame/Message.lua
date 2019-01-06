local assertf                 = require "assertf"
local Button                  = require "Button"
local Color                   = require "color.Color"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local try_invoke              = require "pleasure.try".invoke
local vec2                    = require "linear-algebra.Vector2"

local MessageFrame = {}
MessageFrame.__index = MessageFrame

MessageFrame._kind = ";MessageFrame;Frame;"

local PAD_X =  6
local PAD_Y = 10

local btn_size = vec2(100, 20)
local btn_text_color = Color{0.2, 0.2, 0.2}

setmetatable(MessageFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "MessageFrame constructor must be a table.")
    frame.size = vec2(400, 88)
    MessageFrame.typecheck(frame, "MessageFrame constructor")

    frame._btn_ok = Button {
      text = frame.label_ok or "Ok";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        try_invoke(frame, "option_ok")
        frame:close()
      end;
    }

    frame._pressed_index = nil

    setmetatable(frame, MessageFrame)
    return frame
  end;
})

function MessageFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(type(obj.title) == "string", "Error in %s: Missing/invalid property: 'title' must be a string.", where)
  assertf(not obj.text or type(obj.text) == "string", "Error in %s: Invalid optional property: 'text' must be a string (or nil).", where)
end

function MessageFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";MessageFrame;")
end

function MessageFrame:draw(size)
  local w, h = size.x, size.y
  Images.ninepatch("menu", 0, 16, w, h - 16)
  Images.ninepatch("menu", 0,  0, w, 20)
  love.graphics.print(self.title, PAD_X, 4)
  love.graphics.printf(self.text or "", PAD_X, 28, self.size.x - PAD_X*2, "left")

  pleasure.push_region(self:_btn_bounds())
  love.graphics.setColor(1, 1, 1)
  try_invoke(self._btn_ok, "draw", self)
  pleasure.pop_region()
end

function MessageFrame:_btn_bounds()
  local size = self.size
  local x = (size.x - btn_size.x)/2
  local y = size.y - PAD_Y - btn_size.y
  return x, y, btn_size.x, btn_size.y
end

function MessageFrame:mousepressed(mx, my, button)
  self:request_focus()

  local btn = self._btn_ok
  local x, y = self:_btn_bounds()
  local mx2, my2 = mx - x, my - y
  if element_contains(btn, mx2, my2) then
    btn.pressed = true
    btn.focused = true
    try_invoke(btn, "mousepressed", mx2, my2, button)
  else
    btn.focused = false
  end
end

function MessageFrame:mousemoved(mx, my)
  local btn = self._btn_ok
  local x, y = self:_btn_bounds()
  local mx2, my2 = mx - x, my - y
  if element_contains(btn, mx2, my2) then
    if not btn.hovered then
      try_invoke(btn, "mouseenter", mx2, my2)
      btn.hovered = true
    end
    return try_invoke(btn, "mousemoved", mx2, my2)
  elseif btn.hovered then
    try_invoke(btn, "mouseexit", mx2, my2)
    btn.hovered = false
  end
end

function MessageFrame:mousereleased(mx, my, button)
  local btn = self._btn_ok
  if btn.pressed then
    local x, y = self:_btn_bounds()
    local mx2, my2 = mx - x, my - y
    try_invoke(btn, "mousereleased", mx2, my2, button)
    if btn.pressed and element_contains(btn, mx2, my2) then
      try_invoke(btn, "mouseclicked", mx2, my2, button)
    end
    btn.pressed = false
  end
end

function MessageFrame:keypressed(key)
  if key == "return" then
    try_invoke(self._btn_ok, "mouseclicked")
  end
end

return MessageFrame
