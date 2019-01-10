local app                     = require "app"
local Button                  = require "Button"
local Color                   = require "color.Color"
local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local PixelFrame              = require "frame.Pixel"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local try_invoke              = require "pleasure.try".invoke
local vec2                    = require "linear-algebra.Vector2"
local integer_filter          = require "input.filter.non-negative-integer"
local NewPixelViewFrame = {}
NewPixelViewFrame.__index = NewPixelViewFrame

NewPixelViewFrame._kind = ";NewPixelViewFrame;Frame;"

local PAD_X    = 10
local PAD_Y    = 10
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y + 20

local btn_size = vec2(100, 20)
local btn_text_color = Color{0.2, 0.2, 0.2}

local DEFAULT_VIEW_WIDTH  = 64
local DEFAULT_VIEW_HEIGHT = 64

setmetatable(NewPixelViewFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "NewPixelViewFrame constructor must be a table.")
    frame.size = vec2(400, 88)
    NewPixelViewFrame.typecheck(frame, "NewPixelViewFrame constructor")

    local edit_width = EditableText{
      text = "";
      size = vec2(frame.size.x/2 - OFFSET_X*2, 20);
      hint = ("width (%d)"):format(DEFAULT_VIEW_WIDTH);
      filter = integer_filter;
    }
    frame._edit_width = edit_width

    local edit_height = EditableText{
      text = "";
      size = vec2(frame.size.x/2 - OFFSET_X*2, 20);
      hint = ("height (%d)"):format(DEFAULT_VIEW_HEIGHT);
      filter = integer_filter;
    }
    frame._edit_height = edit_height

    local btn_yes = Button {
      text = "Create";
      size = btn_size:copy();
      text_color = btn_text_color;
      mouseclicked = function ()
        local width  = tonumber(edit_width .text)
        if not width  or width  <= 0 then width  = DEFAULT_VIEW_WIDTH  end

        local height = tonumber(edit_height.text)
        if not height or height <= 0 then height = DEFAULT_VIEW_HEIGHT end

        app.add_view (1, {
          frame = PixelFrame {
            data = love.image.newImageData(width, height);
          };
          pos   = frame.create_pos or app.popup_position();
          scale = 1;
        })
        frame:close()
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

    local ui = { edit_width, edit_height, btn_yes, btn_no }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, NewPixelViewFrame)
    return frame
  end;
})

function NewPixelViewFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function NewPixelViewFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";NewPixelViewFrame;")
end

function NewPixelViewFrame:draw(size)
  local w, h = size.x, size.y
  Images.ninepatch("menu", 0, 16, w, h - 16)
  Images.ninepatch("menu", 0,  0, w, 20)
  love.graphics.print("New Pixel View", 6, 4)

  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
end

function NewPixelViewFrame:_element_bounds(index)
  if index <= 2 then
    local half_width = self.size.x/2
    return OFFSET_X + (index - 1)*half_width, OFFSET_Y, half_width - 2*OFFSET_X, 20
  else
    local size = self.size
    local qx   = size.x/4
    local x = (2*index - 5)*qx - btn_size.x/2
    local y = size.y - PAD_Y - btn_size.y
    return x, y, btn_size.x, btn_size.y
  end
end

function NewPixelViewFrame:mousepressed(mx, my, button)
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

function NewPixelViewFrame:mousemoved(mx, my)
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

function NewPixelViewFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function NewPixelViewFrame:mousereleased(mx, my, button)
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

function NewPixelViewFrame:keypressed(key, scancode, isrepeat)
  if key == "tab" then
    if self._edit_width.focused then
      self._edit_width.focused  = false
      self._edit_height.focused = true
    else
      self._edit_width.focused  = true
      self._edit_height.focused = false
    end
  elseif key == "return" then
    try_invoke(self._btn_yes, "mouseclicked")
  elseif key == "escape" then
    try_invoke(self._btn_no, "mouseclicked")
  elseif self._edit_width.focused then
    self._edit_width:keypressed(key, scancode, isrepeat)
  elseif self._edit_height.focused then
    self._edit_height:keypressed(key, scancode, isrepeat)
  end
end

function NewPixelViewFrame:textinput(text)
  if self._edit_width.focused then
    self._edit_width:textinput(text)
  elseif self._edit_height.focused then
    self._edit_height:textinput(text)
  end
end

function NewPixelViewFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return NewPixelViewFrame
