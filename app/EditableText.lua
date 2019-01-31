local font_writer             = require "util.font_writer"

local pleasure                = require "pleasure"

local Color                   = require "color.Color"
local vec2                    = require "linear-algebra.Vector2"

local clamp                   = require "math.clamp"
local minmax                  = require "math.minmax"
local unicode                 = require "unicode"

local function is_ctrl_down () return love.keyboard.isDown("lctrl" , "rctrl" ) end
local function is_shift_down() return love.keyboard.isDown("lshift", "rshift") end

local is_callable = pleasure.is.callable

local EditableText = {
  x_pad              =  2;
  text_color         = Color{0, 0, 0, 1.0};
  hint_color         = Color{0, 0, 0, 0.3};
  double_click_delay = 0.5;
  font               = love.graphics.newFont(12);
}
EditableText.__index = EditableText

setmetatable(EditableText, {
  __call = function (_, field)
    assert(type(field) == "table", "EditableText constructor must be a table.")
    assert(not field.text or type(field.text) == "string",
      "Error in EditableText constructor: Invalid property: 'text' must be a string (or nil).")
    assert(not field.hint or type(field.hint) == "string",
      "Error in EditableText constructor: Invalid property: 'hint' must be a string (or nil).")
    assert(vec2.is(field.size),
    "Error in EditableText constructor: Invalid property: 'size' must be a Vector2.")

    setmetatable(field, EditableText)

    field.caret =  1
    field.off_x =  0
    field.text  = field.text or ""

    return field
  end;
})

function EditableText:set_text(text)
  self:_set_text(tostring(text or ""))
  self.select = nil
  self.caret  = unicode.len(self.text) + 1
end

function EditableText:_set_text(text)
  if self.filter then
    text = self.filter(text)
  end
  local old_text = self.text
  self.text = text
  if is_callable(self.on_change) then
    self:on_change(text, old_text)
  end
end

function EditableText:_set_caret(new_caret, select)
  self.select = (select or (select == nil and is_shift_down())) and (self.select or self.caret) or nil
  self.caret  = clamp(new_caret, 1, unicode.len(self.text) + 1)
  self:_text_x()
end

function EditableText:_text_x()
  local width = self.size.x

  local left_x  = self.x_pad
  local right_x = left_x + width - 2*self.x_pad
  local caret_x = left_x + self.font:getWidth(unicode.sub(self:text_as_shown(), 1, self.caret - 1))
  local off_x = self.off_x

  if caret_x + off_x < left_x then
    off_x = left_x - caret_x
  end
  if caret_x + off_x >= right_x then
    off_x = right_x - caret_x
  end

  self.off_x = off_x

  return left_x + off_x
end


function EditableText:_paste_text(input)
  local select, old_caret = self.select, self.caret
  local start, stop

  if select then
    start, stop = minmax(select, old_caret)
    self.select = nil
  else
    start, stop = old_caret, old_caret
  end
  input = input:gsub("\n", "")
  self:_set_text(unicode.splice(self.text, start, input, stop - start))
  self:_set_caret(start + unicode.len(input), false)

end

function EditableText:textinput (input)
  self:_paste_text(input)
end

function EditableText:_copy_to_clipboard()
  if self._texttype == "password" then return end
  local select, old_caret = self.select, self.caret
  if not select then return end
  local from, to = minmax(select, old_caret)
  local clip = unicode.sub(self.text, from, to - 1)
  love.system.setClipboardText(clip)
end

function EditableText:_select_all ()
  self.select = 1
  self:_set_caret(unicode.len(self.text) + 1, true)
end

function EditableText:_token_start()
  local pos = self.caret

  while pos > 1
  and unicode.is_alphanumeric(unicode.sub(self.text, pos - 1, pos - 1)) do
    pos = pos - 1
  end

  return pos
end

function EditableText:_token_end()
  local text_len = unicode.len(self.text)
  local pos = self.caret

  while pos <= text_len
  and unicode.is_alphanumeric(unicode.sub(self.text, pos, pos)) do
    pos = pos + 1
  end

  return pos
end

function EditableText:_select_token ()
  if self._texttype == "password" then
    self:_select_all()
  else
    self.select = self:_token_start()
    self:_set_caret(math.max(self:_token_end(), self.select + 1), true)
  end
end

function EditableText:keypressed (key)
  local select, old_caret = self.select, self.caret

  local ctrl_is_down = is_ctrl_down()

  if ctrl_is_down then
    if key == "a" then
      self:_select_all()
      return
    elseif key == "c" then
      self:_copy_to_clipboard()
      return
    elseif key == "v" then
      self:_paste_text(love.system.getClipboardText() or "")
      return
    elseif key == "x" then
      self:_copy_to_clipboard()
      self:_paste_text("")
      return
    end
  end

  if key == "backspace" then
    if select then
      local start  = math.min(select, old_caret)
      local length = math.abs(select - old_caret)
      self:_set_text(unicode.splice(self.text, start, "", length))
      self:_set_caret(start)
      self.select = nil
    elseif self.caret > 1 then
      self:_set_text(unicode.splice(self.text, self.caret - 1, "", 1))
      self:_set_caret(self.caret - 1)
    end
    return
  elseif key == "delete" then
    if select then
      local start  = math.min(select, old_caret)
      local length = math.abs(select - old_caret)
      self:_set_text(unicode.splice(self.text, start, "", length))
      self:_set_caret(start)
      self.select = nil
    else
      self:_set_text(unicode.splice(self.text, self.caret, "", 1))
      self:_set_caret(self.caret)
    end
    return
  end

  if key == "left" then
    self:_set_caret(math.min(ctrl_is_down and self:_token_start() or math.huge, self.caret - 1))
  elseif key == "right" then
    self:_set_caret(math.max(ctrl_is_down and self:_token_end() or 0, self.caret + 1))
  elseif key == "home" then
    self:_set_caret(1)
  elseif key == "end" then
    self:_set_caret(math.huge)
  end
end

function EditableText:_mouse_index (mx, _)
  local text, text_x = self:text_as_shown(), self:_text_x()
  local text_len = unicode.len(text)
  for i = 0, text_len do
    local char_x = text_x + self.font:getWidth(unicode.sub(text, 1, i))
    if char_x >= mx then
      return i
    end
  end
  return text_len + 1
end

function EditableText:mousepressed (mx, my)
  love.keyboard.setTextInput(true)

  local new_caret  = self:_mouse_index(mx, my)
  local last_press = self._last_press
  local timestamp  = love.timer.getTime()

  if self.caret == new_caret
  and last_press
  and last_press + self.double_click_delay > timestamp then
    self._last_press = nil
    self:_select_token()
  else
    self._last_press = timestamp
    self:_set_caret(new_caret)
  end
end

function EditableText:mousedragged1 (mx, my)
  if not self._last_press then return end
  self:_set_caret(self:_mouse_index(mx, my), true)
end

function EditableText:text_as_shown()
  local text = self.text
  if self._texttype == "password" then
    text = ("*"):rep(unicode.len(text))
  end
  return text
end

function EditableText:draw (frame, scale)
  scale = scale or 1
  love.graphics.setColor(0.9, 0.9, 0.9)
  love.graphics.rectangle("fill", 0, 0, self.size.x*scale, self.size.y*scale)
  if self.focused and (not frame or frame:has_focus()) then
    self:draw_active(scale)
  else
    self:draw_default(scale)
  end
end

function EditableText:draw_default (scale)
  self:_set_caret(1, false) -- HACK resets caret & selection when not active

  scale = scale or 1

  local size = self.size
  local text = self:text_as_shown()
  pleasure.push_region(self.x_pad*scale, 0, (size.x - 2*self.x_pad)*scale, size.y*scale)
  pleasure.scale(scale)
  do
    local center_y = size.y/2

    if #text == 0 then
      love.graphics.setColor(self.hint_color)
      font_writer.print_aligned(self.font, self.hint or "Hello", 0, center_y, "left", "center")
    else
      -- TODO if text is to long, add elipsis near right border
      love.graphics.setColor(self.text_color)
      font_writer.print_aligned(self.font, text, 0, center_y, "left", "center")
    end
  end
  pleasure.pop_region()
end

function EditableText:draw_active (scale)
  scale = scale or 1
  local size = self.size
  pleasure.push_region(self.x_pad*scale, 0, (size.x - 2*self.x_pad + 2)*scale, size.y*scale)
  pleasure.scale(scale)
  pleasure.translate(self.off_x, 0)
  do
    local text, caret = self:text_as_shown(), self.caret

    local center_y = size.y/2

    local blink = (love.timer.getTime() % 1 < 0.5)
    if not blink then -- show caret
      local left  = unicode.sub(text, 1, caret - 1)
      local caret_x = self.font:getWidth(left) + 1
      love.graphics.setColor(self.text_color)
      love.graphics.setLineWidth(1)
      love.graphics.line(caret_x, center_y - 6, caret_x, center_y + 6)
    end

    local select = self.select
    if select then
      local start, stop = minmax(select, caret)
      local from_x = self.font:getWidth(unicode.sub(text, 1, start - 1)) + 1
      local selection_width = self.font:getWidth(unicode.sub(text, start, stop - 1))
      local font_height = self.font:getHeight()

      love.graphics.setColor(0.2, 0.6, 0.9)
      love.graphics.rectangle("fill", from_x, center_y - font_height/2, selection_width, font_height)
    end

    love.graphics.setColor(self.text_color)
    font_writer.print_aligned(self.font, text, 0, center_y - 1, "left", "center")
  end

  pleasure.pop_region()
end

return EditableText
