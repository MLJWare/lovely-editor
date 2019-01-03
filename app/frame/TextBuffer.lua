local IOs                     = require "IOs"
local Frame                   = require "Frame"
--local assertf                 = require "assertf"
local pleasure                = require "pleasure"
local StringPacket            = require "packet.String"
local TextBuffer              = require "text.Buffer"
local TextCaret               = require "text.Caret"
local unicode                 = require "unicode"
local topath                  = require "topath"
local ctrl_is_down            = require "util.ctrl_is_down"
local shift_is_down           = require "util.shift_is_down"

local split   = unicode.split
local extract = unicode.extract

-- FIXME doesn't have unicode support yet!!!

--local normal_font = love.graphics.newFont(12)
local monofont    = love.graphics.newFont(topath "res/font/Cousine-Regular.ttf", 12)

local TextBufferFrame = {}
TextBufferFrame.__index = TextBufferFrame

TextBufferFrame._kind = ";TextBufferFrame;TextFrame;Frame;"

TextBufferFrame._selection_color = {0.5, 0.5, 0.5, 0.5}
TextBufferFrame._text_color      = {1, 1, 1, 1}

setmetatable(TextBufferFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "TextBufferFrame constructor must be a table.")
    TextBufferFrame.typecheck(frame, "TextBufferFrame constructor")
    frame._font = monofont
    frame._buffer = TextBuffer{}
    frame._caret  = TextCaret{
      _buffer = frame._buffer;
    }

    local text = tostring(frame.data or "")

    frame.data = StringPacket {
        value = text;
    };

    setmetatable(frame, TextBufferFrame)
    if frame.data then
      frame:paste(text)
    end

    return frame
  end;
})

function TextBufferFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(type(obj.text) == "string", "Error in %s: Missing/invalid property: 'text' must be a string.", where)
end

function TextBufferFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";TextBufferFrame;")
end

TextBufferFrame.gives = IOs{
  {id = "data", kind = StringPacket};
}

function TextBufferFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save
  end
end

function TextBufferFrame:on_save()
  return self._buffer:dump()
end


function TextBufferFrame:draw(size)
  local old_font = love.graphics.getFont()
  love.graphics.setFont(self._font)
  pleasure.push_region(0, 0, size.x, size.y)
  do
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, size.x, size.y)
    love.graphics.setColor(self._text_color)

    local caret = self._caret
    local caret_row = caret:get_row()
    local caret_column = caret:get_column()

    local show_caret = love.timer.getTime()%1 < 0.5

    local selection = caret:has_selection()
    local row1, column1, row2, column2 = caret:selection_range()

    local from = 1
    for index, line in self._buffer:lines(from) do
      local y = (index - from)*15
      if selection and index >= row1 and index <= row2 then
        love.graphics.setColor(self._selection_color)
        self:_draw_selection_bar(index, y, line, row1, column1, row2, column2)
        love.graphics.setColor(self._text_color)
      end
      love.graphics.print(line, 0, y)
      if show_caret and index == caret_row then
        self:_draw_caret(line, caret_column, y)
      end
    end
  end
  pleasure.pop_region()
  love.graphics.setFont(old_font)
end

function TextBufferFrame:_draw_selection_bar(index, y, line, from_row, from_column, caret_row, caret_column)
  if caret_row == from_row then
    -- from-to
    local left   = self._font:getWidth(split(line, from_column))
    local right  = self._font:getWidth(split(line, caret_column))
    local width  = right - left + 1
    local height = self._font:getHeight()
    love.graphics.rectangle("fill", left, y, width, height)
  elseif index == from_row then
    --from-tail
    local left   = self._font:getWidth(split(line, from_column))
    local right  = self._font:getWidth(line)
    local width  = right - left + 1
    local height = self._font:getHeight()
    love.graphics.rectangle("fill", left, y, width, height)
  elseif index == caret_row then
    --head-caret
    local left   = 0
    local right  = self._font:getWidth(split(line, caret_column))
    local width  = right - left + 1
    local height = self._font:getHeight()
    love.graphics.rectangle("fill", left, y, width, height)
  else
    --entire line
    local width  = self._font:getWidth(line) + 1
    local height = self._font:getHeight()
    love.graphics.rectangle("fill", 0, y, width, height)
  end
end

function TextBufferFrame:_draw_caret(line, caret_column, y)
  local x = 1 + self._font:getWidth( (split(line, caret_column)) )
  local lw = love.graphics.getLineWidth()
  local ls = love.graphics.getLineStyle()
  love.graphics.setLineWidth(1)
  love.graphics.setLineStyle("rough")
  love.graphics.line(x, y, x, y + 12)
  love.graphics.setLineWidth(lw)
  love.graphics.setLineStyle(ls)
end

function TextBufferFrame:textinput(input)
  if ctrl_is_down() then return end

  local caret = self._caret
  if caret:has_selection() then
    self:_delete_selection(caret)
  end

  local row = caret:get_row()
  local text = self._buffer:get(row)

  local left, right = split(text, caret:get_column())
  self._buffer:set(row, left..input..right)

  caret:move_right()
end

function TextBufferFrame:_delete_selection(caret)
  local row1, column1, row2, column2 = caret:selection_range()
  local buffer = self._buffer

  if row1 == row2 then
    -- from-to
    local line  = buffer:get(row1)
    local delta = column2 - column1
    local left, _, right = extract(line, column1, delta)
    buffer:set(row1, left..right)
  else
    local left     = split(buffer:get(row1), column1) --from-tail
    local _, right = split(buffer:get(row2), column2) --head-caret
    buffer:set(row1, left..right)
    for row = row2, row1 + 1, -1 do --entire line
      buffer:remove(row)
    end
  end
  caret:stop_selection()
  caret:set(row1, column1)
end

function TextBufferFrame:keypressed(key, _, _)
  local caret = self._caret
  local move = false

  if key == "lshift"
  or key == "rshift" then
    if not caret:has_selection() then
      caret:start_selection()
    end
  elseif not ctrl_is_down() then
    if key == "return" then
      local buffer = self._buffer
      local old_row = caret:get_row()
      local left, right = unicode.split(buffer:get(old_row), caret:get_column())
      buffer:set(old_row, left)
      buffer:add(old_row + 1, right)
      caret:move_down()
      caret:jump_head()
    elseif key == "backspace" then
      if caret:has_selection() then
        self:_delete_selection(caret)
      end
      local buffer = self._buffer
      local old_row    = caret:get_row()
      buffer:set(old_row, unicode.splice(buffer:get(old_row), caret:get_column() - 1, "", 1))
      caret:move_left()
      local new_row = caret:get_row()
      if old_row ~= new_row then -- merge the lines
        local text = buffer:remove(old_row)
        buffer:set(caret:get_row(), buffer:get(caret:get_row())..text)
      end
    elseif key == "delete" then
      if caret:has_selection() then
        self:_delete_selection(caret)
      end
      local buffer = self._buffer

      if caret:get_column() > #caret:current_line() then
        -- merge the lines
        local row = caret:get_row()
        local text = buffer:remove(row + 1) or ""
        buffer:set(row, buffer:get(row)..text)
      else
        buffer:set(caret:get_row(), unicode.splice(buffer:get(caret:get_row()), caret:get_column(), "", 1))
      end
    elseif key == "left" then
      caret:move_left()
      move = true
    elseif key == "right" then
      caret:move_right()
      move = true
    elseif key == "up" then
      move = true
      caret:move_up()
    elseif key == "down" then
      move = true
      caret:move_down()
    elseif key == "home" then
      if ctrl_is_down() then
        caret:jump_top()
      end
      caret:jump_head()
      move = true
    elseif key == "end" then
      if ctrl_is_down() then
        caret:jump_bottom()
      end
      caret:jump_tail()
      move = true
    end
  else
    if key == "return" then
      self:refresh()
    elseif key == "c" then
      if caret:has_selection() then
        love.system.setClipboardText(
          table.concat(
            caret:selection_content(), "\n"))
      end
    elseif key == "x" then
      if caret:has_selection() then
        love.system.setClipboardText(
          table.concat(
            caret:selection_content(), "\n"))
        self:_delete_selection(caret)
      end
    elseif key == "v" then
      if caret:has_selection() then
        self:_delete_selection(caret)
      end
      self:paste(love.system.getClipboardText())
    elseif key == "a" then
      caret:jump_top()
      caret:jump_head()
      caret:start_selection()
      caret:jump_bottom()
      caret:jump_tail()
    end
  end

  if move and not shift_is_down() then
    caret:stop_selection()
  end
end

function TextBufferFrame:paste(text)
  if not text then return end
  text = tostring(text)

  local buffer = self._buffer
  local caret  = self._caret

  local row = caret:get_row()

  local left, right = split(buffer:get(row), caret:get_column())

  local first, rest = text:match"^([^\n]*)\n?(.*)$"
  buffer:set(row, left..first)
  if #rest > 0 then
    for line in rest:gmatch"[^\n]*" do
      row = row + 1
      buffer:add(row, line)
    end
    row = row - 1
  end
  local data = buffer:get(row)
  buffer:set(row, data..right)
  caret:set(row, #data + 1)
end

function TextBufferFrame:mousepressed()
  self:request_focus()
  -- TODO set caret at mouse pos
end

function TextBufferFrame:focuslost()
  if self._buffer._dirty then
    self:refresh()
    self._buffer._dirty = false
  end
end
function TextBufferFrame:refresh()
  self.data.value = self._buffer:dump()
  self.data:inform()
end

function TextBufferFrame:id()
  local filename = self.filename
  if filename then
    return filename:match("[^/]*$")
  end
  return Frame.id(self)
end

return TextBufferFrame
