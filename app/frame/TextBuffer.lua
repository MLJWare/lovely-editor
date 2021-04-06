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

local try_invoke = pleasure.try.invoke

local split   = unicode.split
local extract_left  = unicode.split_left
local is_letters = unicode.is_letters
local is_alphanumeric = unicode.is_alphanumeric
local is_whitespace = unicode.is_whitespace
local is_digits = unicode.is_digits
local string_len = unicode.len
local string_sub = unicode.sub

local function is_empty_or_whitespace(text)
  return text == "" or is_whitespace(text)
end

local function is_identifier_start(char)
  return char == "_" or is_letters(char)
end

local function is_identifier_rest(char)
  return char == "_" or is_alphanumeric(char)
end

-- FIXME doesn't have unicode support yet!!!

local FONT_MONO = love.graphics.newFont(topath "res/font/Cousine-Regular.ttf", 12)

---@class TextBufferFrame : Frame
---@field _buffer TextBuffer
---@field _caret TextCaret
---@field _row_offset integer
---@field _x_offset integer
---@field signal_out Signal
local TextBufferFrame = {
  _font = FONT_MONO,
  _syntax_delimiters = "",
  _syntax_comment_line = "",
  _syntax_string_start = "",
  _syntax_string_escape = "",
  _syntax_string_end = "",
  _syntax_keywords = {},
  _syntax_enabled = false,
}
TextBufferFrame.__index = TextBufferFrame
TextBufferFrame._kind = ";TextBufferFrame;TextFrame;Frame;"

TextBufferFrame._selection_color = pack_color(0.5, 0.5, 0.5, 0.5)
TextBufferFrame._text_color      = pack_color(1.0, 1.0, 1.0, 1.0)
TextBufferFrame._keyword_color   = pack_color(1.0, 0.5, 0.8, 1.0)
TextBufferFrame._delimiter_color = pack_color(0.6, 0.7, 1.0, 1.0)
TextBufferFrame._number_color = pack_color(1.0, 0.55, 0.15, 1.0)

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

TextBufferFrame.takes = IOs{
  {id = "syntax", kind = StringKind};
}

function TextBufferFrame:on_connect(prop, from, data)
  if prop == "syntax" then
    self.signal_syntax = from
    from:listen(self, prop, self.refresh_syntax)
    self:refresh_syntax(prop, data)
  end
end

function TextBufferFrame:refresh_syntax(_, text)
  self._syntax_enabled = not not text
  text = text or ""
  local delimiters = text
  local comment_line = ""
  local keywords = {}

  self._syntax_string_start = ""
  self._syntax_string_end = ""
  self._syntax_string_escape = ""

  local newline_index = text:find("\n")
  if newline_index then
    -- optional delimiters (no separator)
    delimiters, text = split(text, newline_index, 1)
    newline_index = text:find("\n")
    if newline_index then
      -- optional line comment syntax highlighting
      comment_line, text = split(text, newline_index, 1)

      newline_index = text:find("\n")
      if newline_index then
        -- basic (single-line) string syntax highlighting with optional string escapes (no separators)
        local string_syntax
        string_syntax, text = split(text, newline_index, 1)
        local len = string_len(string_syntax)
        local start = len >= 1 and string_sub(string_syntax, 1, 1) or ""
        self._syntax_string_start = start
        self._syntax_string_end = len >= 2 and string_sub(string_syntax, 2, 2) or start
        self._syntax_string_escape = len >= 3 and string_sub(string_syntax, 3, 3) or ""

        -- optional keywords (whitespace separated)
        for token in string.gmatch(text, "%S+") do
          keywords[token] = true
        end
      end
    end
  end

  self._syntax_delimiters = delimiters
  self._syntax_comment_line = comment_line
  self._syntax_keywords = keywords
end

function TextBufferFrame:on_disconnect(prop)
  if prop == "syntax" then
    try_invoke(self.signal_syntax, "unlisten", self, prop, self.refresh_syntax)
    self.signal_syntax = nil
    self:refresh_syntax(prop, nil)
  end
end

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
    local kw_r, kw_g, kw_b, kw_a = unpack_color(self._keyword_color)
    local sr, sg, sb, sa = unpack_color(self._selection_color)
    local del_r, del_g, del_b, del_a = unpack_color(self._delimiter_color)
    local num_r, num_g, num_b, num_a = unpack_color(self._number_color)

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

    local syntax_enabled = self._syntax_enabled

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
      end

      if syntax_enabled then -- SYNTAX HIGHLIGHT
        local keywords = self._syntax_keywords
        local syntax_comment_line = self._syntax_comment_line
        local delimiters = self._syntax_delimiters
        local string_start = self._syntax_string_start
        local string_escape = self._syntax_string_escape
        local string_end = self._syntax_string_end
        local should_highlight_strings = not (is_empty_or_whitespace(string_start) or is_empty_or_whitespace(string_end))
        local include_strings_escape = not is_empty_or_whitespace(string_escape)
        local function is_delimiter(char)
          return delimiters:find(char, 1, true) and true or false
        end

        local font = self._font
        local text_length = string_len(line_text)
        local char_index = 1
        local xoffset2 = xoffset
        while char_index <= text_length do
          local did_consume = false
          local function consume_single(predicate, offset)
            local i = char_index + (offset or 0)
            return i <= text_length and predicate(string_sub(line_text, i, i))
               and 1 or 0
          end

          local function char_at(offset)
            return string_sub(line_text, char_index + offset, char_index + offset)
          end

          local function grab(count)
            return string_sub(line_text, char_index, char_index + count - 1)
          end

          local function consume(predicate1, predicate2, offset)
            predicate2 = predicate2 or predicate1
            local initial_offset = offset or 0
            offset = initial_offset
            if char_index + offset <= text_length and predicate1(char_at(offset)) then
              offset = offset + 1
              while char_index + offset <= text_length and predicate2(char_at(offset)) do
                offset = offset + 1
              end
              return offset - initial_offset
            else
              return 0
            end
          end

          local function advance(token, count)
            xoffset2 = xoffset2 + font:getWidth(token)
            char_index = char_index + count
            did_consume = did_consume or count > 0
          end

          -- consume whitespace
          do
            local count = consume(is_whitespace)
            local token = grab(count)
            advance(token, count)
          end

          -- try consume line comment
          did_consume = not is_empty_or_whitespace(syntax_comment_line)
                        and string.find(line_text, syntax_comment_line, char_index, true) == char_index
          if did_consume then
            local count = consume(function (char) return char ~= "\n" end)
            love.graphics.setColor(tr * 0.5, tg * 0.5, tb * 0.5, ta)
            local token = grab(count)
            love.graphics.print(token, xoffset2, yoffset)
            advance(token, count)
          end

          if not did_consume then
            -- try consume strings (single-line support only)
            if should_highlight_strings and string.find(line_text, string_start, char_index) == char_index then
              local count = 0
              while char_index + count <= text_length do
                count = count + 1
                local char = string_sub(line_text, char_index + count, char_index + count)
                if include_strings_escape and char == string_escape then
                  count = count + 1
                elseif char == string_end then
                  count = count + 1
                  break
                end
              end
              local token = grab(count)
              love.graphics.setColor(0.5, 0.9, 0.3, 1.0)
              love.graphics.print(token, xoffset2, yoffset)
              advance(token, count)
            end
          end

          if not did_consume then
            -- try consume identifiers/keywords
            local count = consume(is_identifier_start, is_identifier_rest)
            local token = grab(count)
            if keywords[token] then
              love.graphics.setColor(kw_r, kw_g, kw_b, kw_a)
            else
              love.graphics.setColor(tr, tg, tb, ta)
            end
            love.graphics.print(token, xoffset2, yoffset)
            advance(token, count)
          end

          if not did_consume then
            -- try consume delimiter
            local count = consume_single(is_delimiter)
            love.graphics.setColor(del_r, del_g, del_b, del_a)
            local token = grab(count)
            love.graphics.print(token, xoffset2, yoffset)
            advance(token, count)
          end

          if not did_consume then
            -- try consume numbers
            local count = consume(is_digits)
            count = count + consume_single(function (char) return char == "." end, count)
            count = count + consume(is_digits, is_digits, count)

            local token = grab(count)
            if token ~= "." then
              love.graphics.setColor(num_r, num_g, num_b, num_a)
              love.graphics.print(token, xoffset2, yoffset)
              advance(token, count)
            end
          end

          if not did_consume then
            -- consume anything (single character)
            love.graphics.setColor(tr, tg, tb, ta)
            local count = 1
            local token = grab(count)
            love.graphics.print(token, xoffset2, yoffset)
            advance(token, count)
          end
        end
      else
        love.graphics.setColor(tr, tg, tb, ta)
        love.graphics.print(line_text, xoffset, yoffset)
      end

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
  love.graphics.setColor(unpack_color(self._text_color))

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
    else
      self:refresh()
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
