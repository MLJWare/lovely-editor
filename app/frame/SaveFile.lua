local app                     = require "app"
local Button                  = require "Button"
local pack_color              = require "util.color.pack"
local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local try_invoke              = require "pleasure.try".invoke
local vec2                    = require "linear-algebra.Vector2"
local YesNoFrame              = require "frame.YesNo"

local _info_ = {}

local SaveFileFrame = {}
SaveFileFrame.__index = SaveFileFrame

SaveFileFrame._kind = ";SaveFileFrame;Frame;"

local PAD_X    = 10
local PAD_Y    = 10
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y + 20

local btn_size = vec2(100, 20)
local btn_text_color = pack_color(0.2, 0.2, 0.2, 1.0)

setmetatable(SaveFileFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "SaveFileFrame constructor must be a table.")
    frame.size = vec2(400, 88)
    SaveFileFrame.typecheck(frame, "SaveFileFrame constructor")

    local edit = EditableText{
      text = "";
      size = vec2(frame.size.x - OFFSET_X*2, 20);
      hint = "filename";
    }
    frame._edit = edit

    local btn_yes = Button {
      text = "Save";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        local filename = edit.text
        if love.filesystem.getInfo(filename, _info_) then
          app.show_popup(YesNoFrame {
            title = "Override?";
            text  = ("File %q already exists. Override?"):format(filename);
            option_yes = function ()
              frame:_save_and_close(filename)
            end;
          })
        else
          frame:_save_and_close(filename)
        end
      end;
    }
    frame._btn_yes = btn_yes

    local btn_no = Button {
      text = "Cancel";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        frame:close()
      end;
    }
    frame._btn_no = btn_no

    local ui = { edit, btn_yes, btn_no }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, SaveFileFrame)
    return frame
  end;
})

function SaveFileFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function SaveFileFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";SaveFileFrame;")
end

function SaveFileFrame:_save_and_close(filename)
  local data = self.action(self.data, filename)
  love.filesystem.write(filename, data)
  self:close()
  try_invoke(self, "on_saved")
end
function SaveFileFrame:draw(size)
  local w, h = size.x, size.y
  Images.ninepatch("menu", 0, 16, w, h - 16)
  Images.ninepatch("menu", 0,  0, w, 20)
  love.graphics.print("Save As:", 6, 4)

  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
end

function SaveFileFrame:_element_bounds(index)
  if index == 1 then
    return OFFSET_X, OFFSET_Y, self.size.x - 2*OFFSET_X, 20
  else
    local size = self.size
    local qx   = size.x/4
    local x = (2*index - 3)*qx - btn_size.x/2
    local y = size.y - PAD_Y - btn_size.y
    return x, y, btn_size.x, btn_size.y
  end
end

function SaveFileFrame:mousepressed(mx, my, button)
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

function SaveFileFrame:mousemoved(mx, my)
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

function SaveFileFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function SaveFileFrame:mousereleased(mx, my, button)
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

function SaveFileFrame:keypressed(key, scancode, isrepeat)
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

function SaveFileFrame:textinput(text)
  if not self._edit.focused then return end
  self._edit:textinput(text)
end

function SaveFileFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return SaveFileFrame
