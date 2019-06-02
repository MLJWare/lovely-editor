local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local try_invoke              = require "pleasure.try".invoke
local settings                = require "settings"

local SettingsFrame = {}
SettingsFrame.__index = SettingsFrame

SettingsFrame._kind = ";SettingsFrame;Frame;"

local PAD_X    = 10
local PAD_Y    = 10
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y + 20

setmetatable(SettingsFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "SettingsFrame constructor must be a table.")
    frame.size_x = 400
    frame.size_y = 400
    SettingsFrame.typecheck(frame, "SettingsFrame constructor")

    local edit = EditableText{
      text = "";
      size_x = frame.size_x - OFFSET_X*2;
      size_y = 20;
      hint = "filename";
    }
    frame._edit = edit

    local ui = { edit }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, SettingsFrame)
    return frame
  end;
})

function SettingsFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function SettingsFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";SettingsFrame;")
end

function SettingsFrame:draw(size_x, size_y, scale)
  pleasure.push_region(0, 0, size_x, size_y)
  pleasure.scale(scale, scale)
  -- FIXME doesnt scale content!!!
  Images.ninepatch("menu", 0, 16, self.size_x, self.size_y - 16)
  Images.ninepatch("menu", 0,  0, self.size_x, 20)
  love.graphics.print("Settings:", 6, 4)

  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
  pleasure.pop_region()
end

function SettingsFrame:_element_bounds(index)
  -- TODO
  if index == 1 then
    return OFFSET_X, OFFSET_Y, self.size_x - 2*OFFSET_X, 20
  end
end

function SettingsFrame:mousepressed(mx, my, button)
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

function SettingsFrame:mousemoved(mx, my)
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

function SettingsFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function SettingsFrame:mousereleased(mx, my, button)
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

function SettingsFrame:keypressed(key, scancode, isrepeat)
  if key == "tab" then
    self._edit.focused = true
  elseif key == "return" then
    try_invoke(self._btn_yes, "mouseclicked")
  elseif key == "escape" then
    try_invoke(self._btn_no, "mouseclicked")
  elseif self._edit.focused then
    self._edit:keypressed(key, scancode, isrepeat)
  end
end

function SettingsFrame:textinput(text)
  if not self._edit.focused then return end
  self._edit:textinput(text)
end

function SettingsFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return SettingsFrame
