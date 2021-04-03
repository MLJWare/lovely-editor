local clamp = require "math.clamp"
local unicode = require "lib.unicode"

local split   = unicode.split
local splice  = unicode.splice
local unicode_len = unicode.len
local unicode_sub = unicode.sub
local extract_left = unicode.split_left
local extract_right = unicode.split_right

local is = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

---@class TextBuffer
--- A simple buffer for storing text, used by TextArea.
local TextBuffer = {}
TextBuffer.__index = TextBuffer
TextBuffer._kind = ";TextBuffer;"

setmetatable(TextBuffer, {
  ---Creates a new TextBuffer
---@param buffer? string[]
---@return TextBuffer
__call = function (_, buffer)
    assert(is_table(buffer), "TextBuffer constructor must be a table.")
    TextBuffer.typecheck(buffer, "TextBuffer constructor")
    buffer[1] = ""
    setmetatable(buffer, TextBuffer)
    return buffer
  end;
})

function TextBuffer.typecheck(--[[obj, where]])
  --assertf(???, "Error in %s: Missing/invalid property: '???' must be a ???.", where)
end

function TextBuffer.is(obj)
  return is_metakind(obj, ";TextBuffer;")
end

function TextBuffer.new(class, buffer)
  buffer = buffer or { "" }
  assert(type(buffer) == "table", "TextBuffer constructor must be a table (or nil).")
  buffer[1] = buffer[1] or  ""
  return setmetatable(buffer, class)
end

--- Retrieves a given line from the buffer.
---@param line_number integer index of the line to retrieve.
---@return string text the text at the given line, or the empty string if the given line doesn't exist.
function TextBuffer:get_line(line_number)
  return rawget(self, line_number) or ""
end

--- Retrieves a character from the buffer.
---@param line_number integer index of the line to retrieve the char from.
---@param column integer column index of the char to retrieve within the line.
---@return string char the char at the given index, or the empty string if the char does not exist.
function TextBuffer:char_at(line_number, column)
  local line = rawget(self, line_number) or ""
  return unicode_sub(line, column, column) or ""
end

--- Sets a given line in the buffer.
---@param line_number integer index of the line to set.
---@param text string the text to set the given line to.
function TextBuffer:set_line(line_number, text)
  self._dirty = true
  line_number = clamp(line_number, 1, #self + 1)
  text = (text or ""):gsub("\t", "  "):gsub("\r", "")
  rawset(self, line_number, text)
end

--- Pastes text into the buffer, starting at a given line number and column (supports newlines).
---@param text string the text to paste into the buffer
---@param line_number integer the line number at which to start pasting the text into the buffer
---@param column integer the column at which to start pasting the text into the buffer
---@return integer pasted_line_number the line number where the pasted text ends
---@return integer pasted_column the column where the pasted text ends
function TextBuffer:paste_text_at(text, line_number, column)
  if not text then return end

  local left, right = split(self:get_line(line_number), column)

  local first, rest = (tostring(text).."\n"):match("^([^\n]*)\n(.*)$")
  self:set_line(line_number, left..first)
  if #rest > 0 then
    for line in rest:gmatch"([^\n]*)\n" do
      line_number = line_number + 1
      self:insert_line(line_number, line)
    end
  end
  local last_pasted_line = self:get_line(line_number)
  self:set_line(line_number, last_pasted_line..right)
  return line_number, unicode_len(last_pasted_line) + 1
end


function TextBuffer:split_line_at(line_number, column)
  local left, right = split(self:get_line(line_number), column)
  self:set_line(line_number, left)
  self:insert_line(line_number + 1, right)
end

function TextBuffer:delete_char_at(line_number, column)
  if line_number < 1 or #self < line_number then return end
  self:set_line(line_number, splice(self:get_line(line_number), column, "", 1))
end

function TextBuffer:delete_range(from_line, from_column, to_line, to_column)
  local max_line = #self + 1

  if from_line > to_line or from_line > max_line or to_line < 1 then
    return
  end

  if from_line < 1 then
    from_line = 1
    from_column = 1
  end

  if to_line > max_line then
    to_line = max_line
    to_column = 2
  end

  self._dirty = true

  if from_line == to_line then
    local line_text = self:get_line(from_line)
    local max_column = unicode_len(line_text) + 1
    from_column = clamp(from_column, 1, max_column)
    to_column = clamp(to_column, 1, max_column)
    if from_column > to_column then
      from_column, to_column = to_column, from_column
    end
    self:set_line(from_line, splice(line_text, from_column, "", to_column - from_column))
  else
    local from_text = self:get_line(from_line)
    from_column = clamp(from_column, 1, unicode_len(from_text) + 1)
    local left     = extract_left(from_text, from_column) --from-tail

    local to_text = self:get_line(to_line)
    to_column = clamp(to_column, 1, unicode_len(to_text) + 1)
    local right = extract_right(to_text, to_column) --head-caret

    for row = to_line, from_line + 1, -1 do --entire line
      self:remove_line(row)
    end
    self:set_line(from_line, left..right)
  end
  return from_line, from_column
end

function TextBuffer:merge_line_with_line_above(line_number)
  local line_text = self:remove_line(line_number)
  self:set_line(line_number - 1, self:get_line(line_number - 1)..line_text)
end

function TextBuffer:merge_with_line_below(line_number)
  local below_text = self:remove_line(line_number + 1) or ""
  self:set_line(line_number, self:get_line(line_number)..below_text)
end


function TextBuffer:insert_line(line_number, text)
  self._dirty = true
  line_number = math.max(1, math.min(line_number, #self + 1))
  text = (text or ""):gsub("\t", "  "):gsub("\r", "")
  table.insert(self, line_number, text or "")
end

function TextBuffer:add_line(text)
  local index = #self
  if self[index] == "" then
    self:insert_line(index, text)
  else
    self:insert_line(index + 1, text)
  end
end

function TextBuffer:remove_line(line_number)
  self._dirty = true
  return table.remove(self, line_number)
end

function TextBuffer:line_count()
  return #self
end

function TextBuffer:lines(from, to)
  if not (from or to) then return ipairs(self) end
  local i = (from or 1) - 1
  to = to or math.huge
  return function ()
    if i < to then
      i = i + 1
      local v = rawget(self, i)
      if v then return i, v end
    end
  end
end

function TextBuffer:dump()
  return table.concat(self, "\n")
end

function TextBuffer:clear()
  self._dirty = true
  for i = #self, 2, -1 do
    rawset(self, i, nil)
  end
  self[1] = ""
end

return TextBuffer
