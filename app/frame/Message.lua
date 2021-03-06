local assertf                 = require "assertf"
local Button                  = require "Button"
local pack_color              = require "util.color.pack"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_opt = pleasure.is.opt
local is_table = pleasure.is.table
local is_string = pleasure.is.string
local is_metakind = pleasure.is.metakind

local MessageFrame = {}
MessageFrame.__index = MessageFrame
MessageFrame._kind = ";MessageFrame;Frame;"

local PAD_X =  6
local PAD_Y = 10

local btn_size_x = 100
local btn_size_y = 20
local btn_text_color = pack_color(0.2, 0.2, 0.2, 1.0)

setmetatable(MessageFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "MessageFrame constructor must be a table.")

    frame.size_x = 400
    frame.size_y = 88
    MessageFrame.typecheck(frame, "MessageFrame constructor")

    frame._btn_ok = Button {
      text = frame.label_ok or "Ok";
      size_x = btn_size_x;
      size_y = btn_size_y;
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
  assertf(is_string(obj.title), "Error in %s: Missing/invalid property: 'title' must be a string.", where)
  assertf(is_opt(obj.text, is_string), "Error in %s: Invalid optional property: 'text' must be a string (or nil).", where)
end

function MessageFrame.is(obj)
  return is_metakind(obj, ";MessageFrame;")
end

function MessageFrame:draw(size_x, size_y)
  local w, h = size_x, size_y
  Images.ninepatch("menu", 0, 16, w, h - 16)
  Images.ninepatch("menu", 0,  0, w, 20)
  love.graphics.print(self.title, PAD_X, 4)
  love.graphics.printf(self.text or "", PAD_X, 28, self.size_x - PAD_X*2, "left")

  pleasure.push_region(self:_btn_bounds())
  love.graphics.setColor(1, 1, 1)
  try_invoke(self._btn_ok, "draw", self)
  pleasure.pop_region()
end

function MessageFrame:_btn_bounds()
  local size_x = self.size_x
  local size_y = self.size_y
  local x = (size_x - btn_size_x)/2
  local y = size_y - PAD_Y - btn_size_y
  return x, y, btn_size_x, btn_size_y
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
