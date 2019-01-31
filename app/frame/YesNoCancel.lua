local assertf                 = require "assertf"
local Button                  = require "Button"
local Color                   = require "color.Color"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local try_invoke              = require "pleasure.try".invoke
local vec2                    = require "linear-algebra.Vector2"

local YesNoCancelFrame = {}
YesNoCancelFrame.__index = YesNoCancelFrame

YesNoCancelFrame._kind = ";YesNoCancelFrame;Frame;"

local PAD_X =  6
local PAD_Y = 10

local btn_size = vec2(100, 20)
local btn_text_color = Color{0.2, 0.2, 0.2}

setmetatable(YesNoCancelFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "YesNoCancelFrame constructor must be a table.")
    frame.size = vec2(400, 88)
    YesNoCancelFrame.typecheck(frame, "YesNoCancelFrame constructor")

    local btn_yes = Button {
      text = frame.label_yes or "Yes";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        try_invoke(frame, "option_yes")
        frame:close()
      end;
    }
    frame._btn_yes = btn_yes

    local btn_no = Button {
      text = frame.label_no or "No";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        try_invoke(frame, "option_no")
        frame:close()
      end;
    }
    frame._btn_no = btn_no

    local btn_cancel = Button {
      text = frame.label_cancel or "Cancel";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        try_invoke(frame, "option_cancel")
        frame:close()
      end;
    }
    frame._btn_cancel = btn_cancel

    local ui = { btn_yes, btn_no, btn_cancel }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, YesNoCancelFrame)
    return frame
  end;
})

function YesNoCancelFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  assertf(type(obj.title) == "string", "Error in %s: Missing/invalid property: 'title' must be a string.", where)
  assertf(not obj.text or type(obj.text) == "string", "Error in %s: Invalid optional property: 'text' must be a string (or nil).", where)
end

function YesNoCancelFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";YesNoCancelFrame;")
end

function YesNoCancelFrame:draw(size)
  local w, h = size.x, size.y
  Images.ninepatch("menu", 0, 16, w, h - 16)
  Images.ninepatch("menu", 0,  0, w, 20)
  love.graphics.print(self.title, PAD_X, 4)
  love.graphics.printf(self.text or "", PAD_X, 28, self.size.x - PAD_X*2, "left")
  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
end

function YesNoCancelFrame:_element_bounds(index)
  local size = self.size
  local qx   = size.x/10
  local x = (3*index - 1)*qx - btn_size.x/2
  local y = size.y - PAD_Y - btn_size.y
  return x, y, btn_size.x, btn_size.y
end

function YesNoCancelFrame:mousepressed(mx, my, button)
  self:request_focus()

  local searching = true
  for index, element in ipairs(self._ui) do
    if searching then
      local x, y = self:_element_bounds(index)
      local mx2, my2 = mx - x, my - y
      if element_contains(element, mx2, my2) then
        self._pressed_index = index
        element.pressed = true
        element.focused = true
        searching = false
        try_invoke(element, "mousepressed", mx2, my2, button)
      else
        element.focused = false
      end
    else
      element.focused = false
    end
  end
end

function YesNoCancelFrame:mousemoved(mx, my)
  for index, element in ipairs(self._ui) do
    local x, y = self:_element_bounds(index)
    local mx2, my2 = mx - x, my - y
    if element_contains(element, mx2, my2) then
      if not element.hovered then
        try_invoke(element, "mouseenter", mx2, my2)
        element.hovered = true
      end
      return try_invoke(element, "mousemoved", mx2, my2)
    elseif element.hovered then
      try_invoke(element, "mouseexit", mx2, my2)
      element.hovered = false
    end
  end
end

function YesNoCancelFrame:mousereleased(mx, my, button)
  local index = self._pressed_index
  if index then
    self._pressed_index = nil
    local x, y = self:_element_bounds(index)
    local element = self._ui[index]
    local mx2, my2 = mx - x, my - y
    try_invoke(element, "mousereleased", mx2, my2, button)
    if element.pressed and element_contains(element, mx2, my2) then
      try_invoke(element, "mouseclicked", mx2, my2, button)
    end
  end

  for _, element in ipairs(self._ui) do
    element.pressed = false
  end
end

function YesNoCancelFrame:keypressed(key)
  if key == "return" then
    try_invoke(self._btn_yes, "mouseclicked")
  elseif key == "backspace" then
    try_invoke(self._btn_no, "mouseclicked")
  elseif key == "escape" then
    try_invoke(self._btn_cancel, "mouseclicked")
  end
end

return YesNoCancelFrame
