local EditableText            = require "EditableText"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local ParticleSettingsFrame = {}
ParticleSettingsFrame.__index = ParticleSettingsFrame

ParticleSettingsFrame._kind = ";ParticleSettingsFrame;Frame;"

local PAD_X    = 6
local PAD_Y    = PAD_X
local OFFSET_X = PAD_X
local OFFSET_Y = PAD_Y

--[[
set:
  BufferSize
  Colors
  Direction
  EmissionArea
  EmissionRate
  EmitterLifetime
  InsertMode
  LinearAcceleration
  LinearDamping
  Offset
  ParticleLifetime
  Position
  Quads
  RadialAcceleration
  RelativeRotation
  Rotation
  SizeVariation
  Sizes
  Speed
  Spin
  SpinVariation
  Spread
  TangentialAcceleration
  Texture

start
stop
update
--]]

local function number_input (frame)
  return EditableText{
    filter = require "input.filter.number";
    text = "";
    size_x = 3*(frame.size_x - OFFSET_X*3)/4;
    size_y = 20;
    hint = "0";
  }
end

local Label = {}
Label.__index = Label
setmetatable(Label, {
  __call = function (_, label)
    return setmetatable(label, Label)
  end;
})
function Label:draw()
  love.graphics.print(self.text)
end

local function label (frame, text)
  return Label {
    text = text;
    size_x = 2*(frame.size_x - OFFSET_X*3)/4;
    size_y = 20;
  }
end

setmetatable(ParticleSettingsFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "ParticleSettingsFrame constructor must be a table.")
    frame.size_x = 400
    local ui = {
      label(frame, "Buffer Size"), number_input(frame);
      label(frame, "Colors (wip)"), number_input(frame);
      label(frame, "Direction"), number_input(frame);
      label(frame, "Emission Area"), number_input(frame);
      label(frame, "Emission Rate"), number_input(frame);
      label(frame, "Emitter Lifetime"), number_input(frame);
      label(frame, "Insert Mode"), number_input(frame);
      label(frame, "Linear Acceleration - min x"), number_input(frame);
      label(frame, "Linear Acceleration - max x"), number_input(frame);
      label(frame, "Linear Acceleration - min y"), number_input(frame);
      label(frame, "Linear Acceleration - max y"), number_input(frame);
      label(frame, "Linear Damping"), number_input(frame);
      label(frame, "Offset"), number_input(frame);
      label(frame, "Particle Lifetime"), number_input(frame);
      label(frame, "Position"), number_input(frame);
      label(frame, "Quads"), number_input(frame);
      label(frame, "Radial Acceleration"), number_input(frame);
      label(frame, "Relative Rotation"), number_input(frame);
      label(frame, "Rotation"), number_input(frame);
      label(frame, "Size Variation"), number_input(frame);
      label(frame, "Sizes"), number_input(frame);
      label(frame, "Speed"), number_input(frame);
      label(frame, "Spin"), number_input(frame);
      label(frame, "Spin Variation"), number_input(frame);
      label(frame, "Spread"), number_input(frame);
      label(frame, "Tangential Acceleration"), number_input(frame);
      label(frame, "Texture"), number_input(frame);
    }
    frame.size_y = math.ceil(#ui/2)*24 + 2*PAD_Y


    ParticleSettingsFrame.typecheck(frame, "ParticleSettingsFrame constructor")

    frame._ui = ui
    frame._pressed_index = nil
    frame._selected_index = nil

    setmetatable(frame, ParticleSettingsFrame)
    return frame
  end;
})

function ParticleSettingsFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ParticleSettingsFrame.is(obj)
  return is_metakind(obj, ";ParticleSettingsFrame;")
end

function ParticleSettingsFrame:draw(size_x, size_y, scale)
  pleasure.push_region(0, 0, size_x, size_y)
  pleasure.scale(scale, scale)
  Images.ninepatch("menu", 0, 0, self.size_x, self.size_y)
  for i, element in ipairs(self._ui) do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(element, "draw", self)
    pleasure.pop_region()
  end
  pleasure.pop_region()
end

function ParticleSettingsFrame:_element_bounds(index)
  local segment = (self.size_x - 3*OFFSET_X)/4
  local ii = index-1
  local xx = ii%2
  local yy = math.floor(ii/2)
  return OFFSET_X + xx*(2*segment + OFFSET_X), OFFSET_Y + 24*yy, 2*segment, 20
end

function ParticleSettingsFrame:mousepressed(mx, my, button)
  self:request_focus()

  local searching = true
  for index, element in ipairs(self._ui) do
    if searching then
      local x, y = self:_element_bounds(index)
      local mx2, my2 = mx - x, my - y
      if element_contains(element, mx2, my2) then
        self._pressed_index = index
        self._selected_index = index
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

function ParticleSettingsFrame:mousemoved(mx, my)
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

function ParticleSettingsFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function ParticleSettingsFrame:mousereleased(mx, my, button)
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

function ParticleSettingsFrame:keypressed(key, scancode, isrepeat)
  if key == "tab" then
    local ui = self._ui
    local selected_index = 2 + ((self._selected_index or 0) % #ui)
    self._selected_index = selected_index
    for index = 1, #ui do
      ui[index].focused = (index == selected_index)
    end
  elseif key == "return" then
    try_invoke(self._btn_yes, "mouseclicked")
  elseif key == "escape" then
    try_invoke(self._btn_no, "mouseclicked")
  elseif self._selected_index then
    self._ui[self._selected_index]:keypressed(key, scancode, isrepeat)
  end
end

function ParticleSettingsFrame:textinput(text)
  if not self._selected_index then return end
  self._ui[self._selected_index]:textinput(text)
end

function ParticleSettingsFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

function ParticleSettingsFrame.id()
  return "Particle Settings"
end

return ParticleSettingsFrame
