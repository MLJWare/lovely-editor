local Button                  = require "Button"
local pack_color              = require "util.color.pack"
local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local RenameFrame = {}
RenameFrame.__index = RenameFrame
RenameFrame._kind = ";RenameFrame;Frame;"

local PAD_X    = 10
local PAD_Y    = 10
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y + 20

local btn_size_x = 100
local btn_size_y = 20
local btn_text_color = pack_color(0.2, 0.2, 0.2, 1.0)

setmetatable(RenameFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "RenameFrame constructor must be a table.")
    frame.size_x = 400
    frame.size_y = 88
    RenameFrame.typecheck(frame, "RenameFrame constructor")

    local edit = EditableText{
      text = "";
      size_x = frame.size_x - OFFSET_X*2;
      size_y = 20;
      hint = "name";
    }
    frame._edit = edit

    local btn_yes = Button {
      text = "Rename";
      size_x = btn_size_x;
      size_y = btn_size_y;
      text_color = btn_text_color;
      mouseclicked = function ()
        try_invoke(frame, "option_yes", edit.text or "")
        frame:close()
      end;
    }
    frame._btn_yes = btn_yes

    local btn_no = Button {
      text = "Cancel";
      size_x = btn_size_x;
      size_y = btn_size_y;
      text_color = btn_text_color;
      mouseclicked = function ()
        try_invoke(frame, "option_no", edit.text or "")
        frame:close()
      end;
    }
    frame._btn_no = btn_no

    local ui = { edit, btn_yes, btn_no }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, RenameFrame)
    return frame
  end;
})

function RenameFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function RenameFrame.is(obj)
  return is_metakind(obj, ";RenameFrame;")
end

function RenameFrame:draw(size_x, size_y)
  Images.ninepatch("menu", 0, 16, size_x, size_y - 16)
  Images.ninepatch("menu", 0,  0, size_x, 20)
  love.graphics.print("Rename:", 6, 4)

  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
end

function RenameFrame:_element_bounds(index)
  if index == 1 then
    return OFFSET_X, OFFSET_Y, self.size_x - 2*OFFSET_X, 20
  else
    local size_x = self.size_x
    local size_y = self.size_y
    local qx   = size_x/4
    local x = (2*index - 3)*qx - btn_size_x/2
    local y = size_y - PAD_Y - btn_size_y
    return x, y, btn_size_x, btn_size_y
  end
end

function RenameFrame:mousepressed(mx, my, button)
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

function RenameFrame:mousemoved(mx, my)
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

function RenameFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function RenameFrame:mousereleased(mx, my, button)
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

function RenameFrame:keypressed(key, scancode, isrepeat)
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

function RenameFrame:textinput(text)
  if not self._edit.focused then return end
  self._edit:textinput(text)
end

function RenameFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return RenameFrame
