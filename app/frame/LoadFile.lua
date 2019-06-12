local app                     = require "app"
local Button                  = require "Button"
local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local MessageFrame            = require "frame.Message"
local pleasure                = require "pleasure"
local pack_color              = require "util.color.pack"
local try_invoke              = pleasure.try.invoke

local _info_ = {}

local error_loading = MessageFrame{
  title = "Error Loading File";
  text  = "";
}

local LoadFileFrame = {}
LoadFileFrame.__index = LoadFileFrame

LoadFileFrame._kind = ";LoadFileFrame;Frame;"

local PAD_X    = 10
local PAD_Y    = 10
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y + 20

local btn_size_x = 100
local btn_size_y = 20
local btn_text_color = pack_color(0.2, 0.2, 0.2, 1.0)

setmetatable(LoadFileFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "LoadFileFrame constructor must be a table.")
    frame.size_x = 400
    frame.size_y = 88
    LoadFileFrame.typecheck(frame, "LoadFileFrame constructor")

    local edit = EditableText{
      text = "";
      size_x = frame.size_x - OFFSET_X*2;
      size_y = 20;
      hint = "filename";
    }
    frame._edit = edit

    local btn_yes = Button {
      text = "Load";
      size_x = btn_size_x;
      size_y = btn_size_y;
      text_color = btn_text_color;
      mouseclicked = function ()
        local filename = edit.text
        if not love.filesystem.getInfo(filename, _info_) then
          app.show_popup(MessageFrame {
            title = "No such file";
            text  = ("File %q does not exists."):format(filename);
          })
        else
          frame:_try_load(filename)
        end
      end;
    }
    frame._btn_yes = btn_yes

    local btn_no = Button {
      text = "Cancel";
      size_x = btn_size_x;
      size_y = btn_size_y;
      text_color = btn_text_color;
      mouseclicked = function ()
        frame:close()
      end;
    }
    frame._btn_no = btn_no

    local ui = { edit, btn_yes, btn_no }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, LoadFileFrame)
    return frame
  end;
})

function LoadFileFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function LoadFileFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";LoadFileFrame;")
end

function LoadFileFrame:_try_load(filename)
  local success, message = pcall(try_invoke, self, "on_load", love.filesystem.newFile(filename), filename)
  if not success then
    error_loading.text = message
    app.show_popup(error_loading)
  else
    self:close()
  end
end

function LoadFileFrame:draw(size_x, size_y)
  Images.ninepatch("menu", 0, 16, size_x, size_y - 16)
  Images.ninepatch("menu", 0,  0, size_x, 20)
  love.graphics.print("Load From:", 6, 4)

  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
end

function LoadFileFrame:_element_bounds(index)
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

function LoadFileFrame:init_popup()
  self:request_focus()

  local ui = self._ui
  for i = 1, #ui do
    ui[i].focused = false
  end
  self._edit.focused = true
end

function LoadFileFrame:mousepressed(mx, my, button)
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

function LoadFileFrame:mousemoved(mx, my)
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

function LoadFileFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function LoadFileFrame:mousereleased(mx, my, button)
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

function LoadFileFrame:keypressed(key, scancode, isrepeat)
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

function LoadFileFrame:textinput(text)
  if not self._edit.focused then return end
  self._edit:textinput(text)
end

function LoadFileFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return LoadFileFrame
