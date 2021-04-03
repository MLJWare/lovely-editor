local clamp = require "math.clamp"
local unicode = require "lib.unicode"
local extract_left = unicode.split_left
local extract_mid = unicode.extract_mid
local extract_right = unicode.split_right
local string_len = unicode.len

local assertf                 = require "assertf"
local TextBuffer              = require "text.Buffer"
local is                      = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

---@class TextCaret
---@field _row number
---@field _column number
---@field _selection_row number|nil
---@field _selection_column number|nil
---@field _buffer TextBuffer
local TextCaret = {}
TextCaret.__index = TextCaret
TextCaret._kind = ";TextCaret;"

setmetatable(TextCaret, {
  __call = function (_, caret)
    assert(is_table(caret), "TextCaret constructor must be a table.")
    TextCaret.typecheck(caret, "TextCaret constructor")
    caret._row    = caret._row    or 1
    caret._column = caret._column or 1
    setmetatable(caret, TextCaret)
    return caret
  end;
})

function TextCaret.typecheck(obj, where)
  assertf(TextBuffer.is(obj._buffer), "Error in %s: Missing/invalid property: '_buffer' must be a TextBuffer.", where)
end

function TextCaret.is(obj)
  return is_metakind(obj, ";TextCaret;")
end

function TextCaret.clone(caret)
  return TextCaret {
    _row           = caret._row;
    _column        = caret._column;
    _select_row    = caret._select_row;
    _select_column = caret._select_column;
  }
end

--- Starts a selection
function TextCaret:start_selection()
  self._selection_row = self._row
  self._selection_column = self._column
end

--- Stops the current selection
function TextCaret:stop_selection()
  self._selection_row = nil
  self._selection_column = nil
end

---Predicate checking whether a selection currently exists.
---@return boolean has_selection whether a selection currently exists.
function TextCaret:has_selection()
  return self._selection_row ~= nil and self._selection_column ~= nil
     and (self._selection_row ~= self._row or self._selection_column ~= self._column)
end

---Returns the range of the current selection.
---@return number from_row
---@return number from_column
---@return number to_row
---@return number to_column
function TextCaret:selection_range()
  local to_row = self._row
  local to_column = self._column
  local from_row = self._selection_row or to_row
  local from_column = self._selection_column or to_column

  if (from_row > to_row)
  or (from_row == to_row and to_column < from_column) then
    from_row, from_column, to_row, to_column = to_row, to_column, from_row, from_column
  end

  return from_row, from_column, to_row, to_column
end

---Returns a copy of the content of the current selection as an array of strings.
---@return string[] content
function TextCaret:selection_content()
  local from_row, from_column, to_row, to_column = self:selection_range()
  local buffer = self._buffer
  if from_row == to_row then
    -- from-to
    return { extract_mid(buffer:get_line(from_row), from_column, to_column - from_column) }
  else
    local right = extract_right(buffer:get_line(from_row), from_column) --from-tail
    local content = { right }
    local size = 2
    for row = from_row + 1, to_row - 1 do --entire line
      rawset(content, size, buffer:get_line(row))
      size = size + 1
    end
    local left = extract_left(buffer:get_line(to_row), to_column) --head-caret
    rawset(content, size, left)
    return content
  end
end

---Returns a copy of the currently selected text.
---@return string selection_text  the currently selected text.
function TextCaret:selection_text()
  return table.concat(self:selection_content(), "\n")
end

--- Returns the text at the current row of the caret.
---@return string text_at_row the text at the current row of the caret.
function TextCaret:text_at_row()
  return self._buffer:get_line(self._row)
end

---Moves the caret `count` (default 1) character to the left.
---@param count? integer the amount of characters the caret should move by.
function TextCaret:move_left(count)
  for _ = 1, count or 1 do
    if self._column > 1 then
      self._column = self._column - 1
    else
      self:set(self._row - 1, math.huge)
    end
  end
end

---Moves the caret `count` (default 1) character to the right.
---@param count? integer the amount of characters the caret should move by.
function TextCaret:move_right(count)
  for _ = 1, count or 1 do
    if self._column <= string_len(self:text_at_row()) then
      self._column = self._column + 1
    elseif self._row < self._buffer:line_count() then
      self:set(self._row + 1, 1)
    end
  end
end

---Moves the caret `count` (default 1) rows up.
---@param count? integer the amount of rows the caret should move by.
function TextCaret:move_up(count)
  for _ = 1, count or 1 do
    if self._row <= 1 then
      self._column = 1
    else
      self:set(self._row - 1, self._column)
    end
  end
end

---Moves the caret `count` (default 1) rows down.
---@param count? integer the amount of rows the caret should move by.
function TextCaret:move_down(count)
  for _ = 1, count or 1 do
    if self._row == self._buffer:line_count() then
      self:set_column(math.huge)
    else
      self:set(self._row + 1, self._column)
    end
  end
end

---Moves the caret to the beginning of the current line.
function TextCaret:jump_head()
  self:set_column(1)
end

---Moves the caret to the end of the current line.
function TextCaret:jump_tail()
  self:set_column(math.huge)
end

---Moves the caret to the first line.
function TextCaret:jump_top()
  self:set(1, self._column)
end

---Moves the caret to the last line.
function TextCaret:jump_bottom()
  self:set(math.huge, self._column)
end

---Resets the position of the caret, by moving it to the start of the first line.
function TextCaret:reset()
  self:set(1, 1)
end

---Sets the position of the caret to a given row and column.
---Note that if the provided position is outside the valid range, the caret will be moved to the nearest valid position.
---@param new_row integer the intended new row of the caret.
---@param new_column integer the intended new column of the caret.
function TextCaret:set(new_row, new_column)
  self:set_row(new_row)
  self:set_column(new_column)
end

---Sets the row of the caret.
---Note that if the provided row is outside the valid range, the caret will be moved to the nearest valid row.
---@param new_row integer the intended new row of the caret.
function TextCaret:set_row(new_row)
  self._row = clamp(new_row, 1, self._buffer:line_count())
end

---Sets the column of the caret.
---Note that if the provided column index is outside the valid range, the caret will be moved to the nearest valid column.
---@param new_column integer the intended new column of the caret.
function TextCaret:set_column(new_column)
  self._column = clamp(new_column, 1, string_len(self:text_at_row()) + 1)
end

---Returns the position of the caret as a row and column index.
---@return integer row the current row index of the caret.
---@return integer column the current column index of the caret.
function TextCaret:pos()
  return self._row, self._column
end

---Predicate checking whether the caret is at the beginning of current line.
---@return boolean is_at_line_start whether the caret is at the beginning of current line.
function TextCaret:is_at_line_start()
  return self._column == 1
end

---Predicate checking whether the caret is at the end of the current line.
---@return boolean is_at_line_end whether the caret is at the end of the current line.
function TextCaret:is_at_line_end()
  return self._column > string_len(self:text_at_row())
end

---Predicate checking whether the caret is at the beginning of the buffer, i.e. at the start of the first line.
---@return boolean is_at_buffer_start whether the caret is at the beginning of the buffer, i.e. at the start of the first line.
function TextCaret:is_at_buffer_start()
  return self._row == 1 and self._column == 1
end

---Predicate checking whether the caret is at the end of the buffer, i.e. at the end of the last line.
---@return boolean is_at_buffer_end whether the caret is at the end of the buffer, i.e. at the end of the last line.
function TextCaret:is_at_buffer_end()
  return self._row >= self._buffer:line_count()
     and self._column > string_len(self:text_at_row())
end

return TextCaret
