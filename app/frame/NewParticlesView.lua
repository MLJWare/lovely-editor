local app                     = require "app"
local Button                  = require "Button"
local pack_color              = require "util.color.pack"
local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local ParticlesFrame          = require "frame.Particles"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local try_invoke              = require ("pleasure.try").invoke
local integer_filter          = require "input.filter.non-negative-integer"
local NewParticlesViewFrame = {}
NewParticlesViewFrame.__index = NewParticlesViewFrame

NewParticlesViewFrame._kind = ";NewParticlesViewFrame;Frame;"

local PAD_X    = 10
local PAD_Y    = 10
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y + 20

local btn_size_x = 100
local btn_size_y = 20
local btn_text_color = pack_color(0.2, 0.2, 0.2, 1.0)

local DEFAULT_VIEW_WIDTH  = 64
local DEFAULT_VIEW_HEIGHT = 64

setmetatable(NewParticlesViewFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "NewParticlesViewFrame constructor must be a table.")
    frame.size_x = 400
    frame.size_y = 88
    NewParticlesViewFrame.typecheck(frame, "NewParticlesViewFrame constructor")

    local edit_width = EditableText{
      text = "";
      size_x = frame.size_x/2 - OFFSET_X*2;
      size_y = 20;
      hint = (("width (%d)"):format(DEFAULT_VIEW_WIDTH));
      filter = integer_filter;
    }
    frame._edit_width = edit_width

    local edit_height = EditableText{
      text = "";
      size_x = frame.size_x/2 - OFFSET_X*2;
      size_y = 20;
      hint = (("height (%d)"):format(DEFAULT_VIEW_HEIGHT));
      filter = integer_filter;
    }
    frame._edit_height = edit_height

    local btn_yes = Button {
      text = "Create";
      size_x = btn_size_x;
      size_y = btn_size_y;
      text_color = btn_text_color;
      mouseclicked = function ()
        local width  = tonumber(edit_width .text)
        if not width  or width  <= 0 then width  = DEFAULT_VIEW_WIDTH  end

        local height = tonumber(edit_height.text)
        if not height or height <= 0 then height = DEFAULT_VIEW_HEIGHT end

        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (1, {
          frame = ParticlesFrame {
            size_x = width;
            size_y = height;
          };
          pos_x = frame.create_pos_x or popup_x;
          pos_y = frame.create_pos_y or popup_y;
          scale = 1;
        })
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
        frame:close()
      end;
    }
    frame._btn_no = btn_no

    local ui = { edit_width, edit_height, btn_yes, btn_no }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, NewParticlesViewFrame)
    return frame
  end;
})

function NewParticlesViewFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function NewParticlesViewFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";NewParticlesViewFrame;")
end

function NewParticlesViewFrame:draw(size_x, size_y)
  local w, h = size_x, size_y
  Images.ninepatch("menu", 0, 16, w, h - 16)
  Images.ninepatch("menu", 0,  0, w, 20)
  love.graphics.print("New Particles View", 6, 4)

  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
end

function NewParticlesViewFrame:_element_bounds(index)
  if index <= 2 then
    local half_width = self.size_x/2
    return OFFSET_X + (index - 1)*half_width, OFFSET_Y, half_width - 2*OFFSET_X, 20
  else
    local size_x = self.size_x
    local size_y = self.size_y
    local qx   = size_x/4
    local x = (2*index - 5)*qx - btn_size_x/2
    local y = size_y - PAD_Y - btn_size_y
    return x, y, btn_size_x, btn_size_y
  end
end

function NewParticlesViewFrame:mousepressed(mx, my, button)
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

function NewParticlesViewFrame:mousemoved(mx, my)
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

function NewParticlesViewFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function NewParticlesViewFrame:mousereleased(mx, my, button)
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

function NewParticlesViewFrame:keypressed(key, scancode, isrepeat)
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

function NewParticlesViewFrame:textinput(text)
  if self._edit_width.focused then
    self._edit_width:textinput(text)
  elseif self._edit_height.focused then
    self._edit_height:textinput(text)
  end
end

function NewParticlesViewFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return NewParticlesViewFrame
