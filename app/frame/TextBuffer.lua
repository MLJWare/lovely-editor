local IOs                     = require "IOs"
local Frame                   = require "Frame"
local pleasure                = require "pleasure"
local pack_color              = require "util.color.pack"
local unpack_color            = require "util.color.unpack"
local Signal                  = require "Signal"
local StringKind              = require "Kind.String"
local TextBuffer              = require "text.Buffer"
local TextCaret               = require "text.Caret"
local unicode                 = require "unicode"
local topath                  = require "topath"
local alt_is_down             = require "util.alt_is_down"
local ctrl_is_down            = require "util.ctrl_is_down"
local shift_is_down           = require "util.shift_is_down"

local clamp         = require "math.clamp"

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local split   = unicode.split
local extract_left  = unicode.split_left
local is_alphanumeric = unicode.is_alphanumeric
local string_len = unicode.len
local string_sub = unicode.sub

-- FIXME doesn't have unicode support yet!!!

local FONT_MONO = love.graphics.newFont(topath "res/font/Cousine-Regular.ttf", 12)

---@class TextBufferFrame : Frame
---@field x number x-position
---@field y number y-position
---@field size_x number width
---@field size_y number height
---@field _buffer TextBuffer
---@field _caret TextCaret
---@field _row_offset integer
---@field _x_offset integer
---@field signal_out Signal
local TextBufferFrame = {
  _font = FONT_MONO
}
TextBufferFrame.__index = TextBufferFrame
TextBufferFrame._kind = ";TextBufferFrame;TextFrame;Frame;"

TextBufferFrame._selection_color = pack_color(0.5, 0.5, 0.5, 0.5)
TextBufferFrame._text_color      = pack_color(1.0, 1.0, 1.0, 1.0)

setmetatable(TextBufferFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "TextBufferFrame constructor must be a table.")
    TextBufferFrame.typecheck(frame, "TextBufferFrame constructor")
    frame._font = FONT_MONO
    frame._buffer = TextBuffer{}
    frame._caret  = TextCaret{
      _buffer = frame._buffer;
    }
    frame._row_offset = 0
    frame._x_offset = -10

    local text = tostring(frame.data or "")

    frame.data = text

    frame.signal_out = Signal {
      kind = StringKind;
      on_connect = function ()
        return frame.data
      end;
    }

    setmetatable(frame, TextBufferFrame)
    if frame.data then
      frame:paste(text)
    end

    return frame
  end;
})

function TextBufferFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function TextBufferFrame.is(obj)
  return is_metakind(obj, ";TextBufferFrame;")
end

TextBufferFrame.gives = IOs{
  {id = "signal_out", kind = StringKind};
}

function TextBufferFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save
  end
end

function TextBufferFrame:on_save()
  return self._buffer:dump()
end

local app
function TextBufferFrame:_view_render_scale()
  app = app or require "app"
  return app.project.viewport:view_render_scale(self._view_)
end

function TextBufferFrame:_convert_mouse_pos(mx, my)
  local scale = self:_view_render_scale()
  mx = mx * scale
  my = my * scale

  local line_height = self:_line_height()
  local row = 1 + math.floor((my / line_height) + self._row_offset)

  local buffer = self._buffer

  local max_row = buffer:line_count() + 1

  if row > max_row then
    return max_row, string_len(buffer:get_line(max_row)) + 1
  end

  local font = self._font
  local row_text = buffer:get_line(row)
  local max_column = string_len(row_text) + 1
  mx = mx + self._x_offset
  local column = 1
  while column <= max_column and font:getWidth(string_sub(row_text, 1, column)) < mx do
    column = column + 1
  end
  return row, column
end

function TextBufferFrame:mousepressed(mx, my)
  if not (self:has_focus() or self:request_focus()) then return end

  love.keyboard.setTextInput(true)

  local caret = self._caret
  caret:stop_selection()
  caret:set(self:_convert_mouse_pos(mx, my))


  -- TODO set caret at mouse pos
end

function TextBufferFrame:mousedragged1(mx, my, _, _, _)
  if not self:has_focus() then return end

  local caret = self._caret
  if not caret:has_selection() then
    caret:start_selection()
  end
  caret:set(self:_convert_mouse_pos(mx, my))
  self:_ensure_caret_is_visible()
end

local ROW_SCROLL_SPEED = 1.0
local X_SCROLL_SPEED = 20.0

function TextBufferFrame:wheelmoved(dx, dy)
  if shift_is_down() then
    dx, dy = dy, dx
  end

  -- TODO clamp _x_offset based on width of the longest line in the buffer (need to keep track of the length of the longest line at all times)
  self._x_offset = math.max(self._x_offset - dx * X_SCROLL_SPEED, -10)
  self._row_offset = clamp(self._row_offset - dy * ROW_SCROLL_SPEED, 0, self._buffer:line_count() - 2)
end

function TextBufferFrame:draw(size_x, size_y)
  local old_font = love.graphics.getFont()
  love.graphics.setFont(self._font)
  pleasure.push_region(0, 0, size_x, size_y)
  do
    local tr, tg, tb, ta = unpack_color(self._text_color)
    local sr, sg, sb, sa = unpack_color(self._selection_color)

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, size_x, size_y)
    love.graphics.setColor(tr, tg, tb, ta)

    local caret = self._caret
    local caret_row, caret_column = caret:pos()

    local show_caret = self:has_focus() and love.timer.getTime()%1 < 0.5

    local has_selection = caret:has_selection()
    local selection_from_row, selection_from_column, selection_to_row, selection_to_column = caret:selection_range()

    local line_height = self:_line_height()

    local row_offset = self._row_offset
    local line_offset = math.floor(row_offset)
    local from_line = line_offset + 1
    local lines_to_show = math.ceil(size_y / line_height) + 1
    local to_line = line_offset + lines_to_show

    row_offset = row_offset - line_offset

    local xoffset = -self._x_offset

    for index, line_text in self._buffer:lines(from_line, to_line) do
      local yoffset = (index - from_line - row_offset) * line_height
      if has_selection and index >= selection_from_row and index <= selection_to_row then
        love.graphics.setColor(sr, sg, sb, sa)
        self:_draw_selection_bar(
          index,
          xoffset,
          yoffset,
          line_text,
          selection_from_row,
          selection_from_column,
          selection_to_row,
          selection_to_column
        )
        love.graphics.setColor(tr, tg, tb, ta)
      end
      love.graphics.print(line_text, xoffset, yoffset)
      if show_caret and index == caret_row then
        self:_draw_caret(line_text, caret_column, xoffset, yoffset)
      end
    end
  end
  pleasure.pop_region()
  love.graphics.setFont(old_font)
end

-- _draw_selection_bar(index, y, line, from_row, from_column, caret_row, caret_column)
function TextBufferFrame:_draw_selection_bar(index, x, y, line_text, from_row, from_column, to_row, to_column)
  local font = self._font
  local line_height = self:_line_height()
  if to_row == from_row then
    -- from-to
    local left = font:getWidth(split(line_text, from_column))
    local right = font:getWidth(split(line_text, to_column))
    local width = right - left + 1
    love.graphics.rectangle("fill", x + left, y, width, line_height)
  elseif index == from_row then
    --from-tail
    local left = font:getWidth(split(line_text, from_column))
    local right = font:getWidth(line_text)
    local width = right - left + 1
    love.graphics.rectangle("fill", x + left, y, width, line_height)
  elseif index == to_row then
    --head-caret
    local right = font:getWidth(split(line_text, to_column))
    local width = right + 1
    love.graphics.rectangle("fill", x, y, width, line_height)
  else
    --entire line
    local width = font:getWidth(line_text) + 1
    love.graphics.rectangle("fill", x, y, width, line_height)
  end
end

function TextBufferFrame:_draw_caret(line_text, column, x, y)
  local font = self._font

  local line_width = love.graphics.getLineWidth()
  local line_style = love.graphics.getLineStyle()
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("rough")

  local final_x = 1 + x + font:getWidth((split(line_text, column)))
  love.graphics.line(final_x, y, final_x, y + font:getHeight())

  love.graphics.setLineWidth(line_width)
  love.graphics.setLineStyle(line_style)
end

function TextBufferFrame:textinput(input_text)
  if ctrl_is_down() and not alt_is_down() then return end

  local caret = self._caret
  if caret:has_selection() then
    self:_delete_selection(caret)
  end

  caret:stop_selection()
  caret:set(self._buffer:paste_text_at(input_text, caret._row, caret._column))
  self:_ensure_caret_is_visible()
end

---@param caret TextCaret
function TextBufferFrame:_delete_selection(caret)
  caret:set(self._buffer:delete_range(caret:selection_range()))
  caret:stop_selection()
end

function TextBufferFrame:_delete_at_caret()
  local caret = self._caret
  if caret._column > string_len(caret:text_at_row()) then
    self._buffer:merge_with_line_below(caret._row)
  else
    self._buffer:delete_char_at(caret:pos())
  end
end

---@param key string
function TextBufferFrame:keypressed(key, _, _)
  if alt_is_down() then return end

  if key == "lctrl" or key == "rctrl"
  or key == "lalt" or key == "ralt"
  or key == "lshift" or key == "rshift" then return end

  local caret = self._caret
  local buffer = self._buffer

  local holding_shift = shift_is_down()
  local holding_ctrl = ctrl_is_down()

  local should_make_selection = holding_shift and not caret:has_selection()

  local move = false
  local stop_selection_if_moved = true

  if key == "return" then
    if not holding_ctrl then
      if caret:has_selection() then
        self:_delete_selection(caret)
      end
      buffer:split_line_at(caret:pos())
      caret:move_right()
      move = true
    end
  elseif key == "home" then
    if should_make_selection then
      caret:start_selection()
    end

    if holding_ctrl then
      caret:jump_top()
    end
    caret:jump_head()
    move = true
  elseif key == "end" then
    if should_make_selection then
      caret:start_selection()
    end

    if holding_ctrl then
      caret:jump_bottom()
    end
    caret:jump_tail()
    move = true
  elseif key == "left" then
    if should_make_selection then
      caret:start_selection()
    end

    if holding_ctrl then
      -- move by one "token" to the left
      repeat
        caret:move_left()
      until not is_alphanumeric(buffer:char_at(caret._row, caret._column - 1))
        or caret:is_at_line_start()
    else
      caret:move_left()
    end
    move = true
  elseif key == "right" then
    if should_make_selection then
      caret:start_selection()
    end

    if holding_ctrl then
      -- move by one "token" to the right
      repeat
        caret:move_right()
      until not is_alphanumeric(buffer:char_at(caret:pos()))
        or caret:is_at_line_end()
    else
      caret:move_right()
    end
    move = true
  elseif key == "up" then
    if should_make_selection then
      caret:start_selection()
    end

    if holding_ctrl and not holding_shift and caret._row > 1 then
      --swap the current line with the one above
      local this_line = buffer:get_line(caret._row)
      local line_above = buffer:get_line(caret._row - 1)
      buffer:set_line(caret._row, line_above)
      buffer:set_line(caret._row - 1, this_line)
    end
    caret:move_up()
    move = true
  elseif key == "down" then
    if should_make_selection then
      caret:start_selection()
    end

    if holding_ctrl and not holding_shift and caret._row < #buffer then
      --swap the current line with the one below
      local this_line = buffer:get_line(caret._row)
      local line_above = buffer:get_line(caret._row + 1)
      buffer:set_line(caret._row, line_above)
      buffer:set_line(caret._row + 1, this_line)
    end
    caret:move_down()
    move = true
  elseif holding_ctrl then
    if key == "c" then -- copy
      if caret:has_selection() then
        love.system.setClipboardText(caret:selection_text())
      else
        love.system.setClipboardText(caret:text_at_row())
      end
    elseif key == "x" then -- cut
      if caret:has_selection() then
        love.system.setClipboardText(caret:selection_text())
        self:_delete_selection(caret)
      else
        love.system.setClipboardText(caret:text_at_row())
        buffer:remove_line(caret._row)
        caret:jump_head()
      end
      move = true
    elseif key == "v" then -- paste
      if caret:has_selection() then
        self:_delete_selection(caret)
      end
      self:paste(love.system.getClipboardText())
      move = true
    elseif key == "a" then -- select all
      caret:jump_top()
      caret:jump_head()
      caret:start_selection()
      caret:jump_bottom()
      caret:jump_tail()
      stop_selection_if_moved = false
      move = true
    end
  elseif key == "backspace" then
    if caret:has_selection() then
      self:_delete_selection(caret)
    elseif caret._row > 1 or caret._column > 1 then
      caret:move_left()
      self:_delete_at_caret()
    end
    move = true
  elseif key == "delete" then
    if caret:has_selection() then
      self:_delete_selection(caret)
    else
      self:_delete_at_caret()
    end
    move = true
  else
    return
  end

  if move then
    self:_ensure_caret_is_visible()
    if not holding_shift and stop_selection_if_moved then
      caret:stop_selection()
    end
  end
end

function TextBufferFrame:_line_height()
  return math.ceil(self._font:getHeight() * 1.1)
end

function TextBufferFrame:_ensure_caret_is_visible()
  local scale = self:_view_render_scale()
  self:_ensure_caret_row_is_visible(scale)
  self:_ensure_caret_column_is_visible(scale)
end

function TextBufferFrame:_ensure_caret_row_is_visible(scale)
  local line_height = self:_line_height()

  local row_with_caret = self._caret._row
  local row_offset = self._row_offset

  local first_visible_row = row_offset + 1

  if row_with_caret < first_visible_row then
    self._row_offset = row_with_caret - 1
    return
  end

  local size_y = scale * self.size_y
  local number_of_visible_lines = math.floor(size_y / line_height)

  local last_visible_row = first_visible_row + number_of_visible_lines - 1
  if last_visible_row < row_with_caret then
    self._row_offset = row_with_caret - number_of_visible_lines
    return
  end
end

function TextBufferFrame:_ensure_caret_column_is_visible(scale)
  local caret = self._caret
  local width_of_text_left_of_caret = self._font:getWidth(extract_left(caret:text_at_row(), caret._column))

  local x_offset = self._x_offset

  local min_visible_width = x_offset

  if width_of_text_left_of_caret - 10 < min_visible_width then
    self._x_offset = width_of_text_left_of_caret - 10
    return
  end

  local size_x = scale * self.size_x

  local max_visible_width = x_offset + size_x

  if max_visible_width < width_of_text_left_of_caret + 10 then
    self._x_offset = width_of_text_left_of_caret + 10 - size_x
    return
  end
end

function TextBufferFrame:paste(text)
  if not text then return end

  local caret = self._caret
  caret:set(self._buffer:paste_text_at(text, caret:pos()))
end

function TextBufferFrame:focuslost()
  if self._buffer._dirty then
    self:refresh()
    self._buffer._dirty = false
  end
end

function TextBufferFrame:refresh()
  local data = self._buffer:dump()
  self.data = data
  self.signal_out:inform(data)
end

function TextBufferFrame:serialize()
  return ([[TextBufferFrame {
    size_x = %s;
    size_y = %s;
    data = %q;
  }]]):format(self.size_x, self.size_y, self._buffer:dump())
end

function TextBufferFrame:id()
  local filename = self.filename
  if filename then
    return filename:match("[^/]*$")
  end
  return "TextBuffer"
end

return TextBufferFrame
