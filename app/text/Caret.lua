local assertf                 = require "assertf"
local clamp                   = require "math.clamp"
local extract                 = require "util.string.extract"
local split                   = require "util.string.split"
local TextBuffer              = require "text.Buffer"

local TextCaret = {}
TextCaret.__index = TextCaret

TextCaret._kind = ";TextCaret;"

setmetatable(TextCaret, {
  __call = function (_, caret)
    assert(type(caret) == "table", "TextCaret constructor must be a table.")
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
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";TextCaret;")
end

function TextCaret.clone(caret)
  return TextCaret {
    _row           = caret._row;
    _column        = caret._column;
    _select_row    = caret._select_row;
    _select_column = caret._select_column;
  }
end

function TextCaret:start_selection()
  self._select_row    = self._row
  self._select_column = self._column
end

function TextCaret:selection_range()
  local row2    = self._row
  local column2 = self._column
  local row1    = self._select_row or row2
  local column1 = self._select_column or column2

  if (row1 > row2)
  or (row1 == row2 and column2 < column1) then
    row1, column1, row2, column2 = row2, column2, row1, column1
  end

  return row1, column1, row2, column2
end

function TextCaret:selection_content()
  local row1, column1, row2, column2 = self:selection_range()
  local buffer = self._buffer
  local content

  if row1 == row2 then
    -- from-to
    local line  = buffer:get(row1)
    local delta = column2 - column1
    local left, _, right = extract(line, column1, delta)
    content = {
      left..right
    }
  else
    local _, right = split(buffer:get(row1), column1) --from-tail
    content = { right }
    local size = 2
    for row = row1 + 1, row2 - 1 do --entire line
      content[size] = buffer:get(row)
      size = size + 1
    end
    local left = split(buffer:get(row2), column2) --head-caret
    content[size] = left
  end
  return content
end

function TextCaret:has_selection()
  return (self._select_row and self._select_column) and true or false
end

function TextCaret:stop_selection()
  self._select_row    = nil
  self._select_column = nil
end

function TextCaret:current_line()
  return self._buffer:get(self._row)
end

function TextCaret:move_left(count)
  for _ = 1, count or 1 do
    if self._column > 1 then
      self._column = self._column - 1
    else
      self:set(self._row - 1, math.huge)
    end
  end
end

function TextCaret:move_right(count)
  for _ = 1, count or 1 do
      if self._column <= #self:current_line() then
      self._column = self._column + 1
    elseif self._row < self._buffer:line_count() then
      self:set(self._row + 1, 1)
    end
  end
end

function TextCaret:move_up(count)
  for _ = 1, count or 1 do
    if self._row <= 1 then
      self._column = 1
    else
      self:set(self._row - 1, self._column)
    end
  end
end

function TextCaret:move_down(count)
  for _ = 1, count or 1 do
    if self._row == self._buffer:line_count() then
      self:set_column(math.huge)
    else
      self:set(self._row + 1, self._column)
    end
  end
end

function TextCaret:jump_head()
  self:set_column(1)
end

function TextCaret:jump_tail()
  self:set_column(math.huge)
end

function TextCaret:jump_top()
  self:set(1, self._column)
end

function TextCaret:jump_bottom()
  self:set(math.huge, self._column)
end

function TextCaret:reset()
  self:set(1, 1)
end

function TextCaret:_buffer()
  return self._buffer
end

function TextCaret:set(new_row, new_column)
  self:set_row   (new_row)
  self:set_column(new_column)
end

function TextCaret:set_row(new_row)
  self._row = clamp(new_row, 1, self._buffer:line_count())
end

function TextCaret:set_column(new_column)
  self._column = clamp(new_column, 1, #self:current_line() + 1)
end

function TextCaret:get_row()
  return self._row
end

function TextCaret:get_column()
  return self._column
end

return TextCaret
