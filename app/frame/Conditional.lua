-- FIXME !!!!!!!

local Frame                   = require "Frame"
local Group                   = require "frame.comp.Group"
local pleasure                = require "pleasure"
local EditableText            = require "EditableText"
local NoKind                  = require "Kind.None"
local NumberKind              = require "Kind.Number"
local StringKind              = require "Kind.String"
local font_writer             = require "util.font_writer"
local generate_clause         = require "frame.comp.generate_clause"
local try_invoke              = pleasure.try.invoke

local default_condition = function () return true end

local ConditionalFrame = {}
ConditionalFrame.__index = ConditionalFrame

ConditionalFrame._kind = ";ConditionalFrame;Frame;"

setmetatable(ConditionalFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ConditionalFrame constructor must be a table.")

    frame.size_x = frame.size_x or 256
    frame.size_y = frame.size_y or 58

    ConditionalFrame.typecheck(frame, "ConditionalFrame constructor")

    frame._edit_x = 0
    frame._edit_y = 0
    frame._edit_column = 1
    frame._edit_row = 1

    frame._edit = EditableText{
      text   = "";
      size_x = 0;
      size_y = 0;
      hint   = "";
    }

    frame._input_count = 2

    frame._inputs = {}
    frame._conditions = {}
    frame._value_gens = {}

    frame._data = Group{
      _data = frame._data or {
        "a < 10", "1";
        "", "2";
        "", "3";
      }
    }

    frame.result = nil

    setmetatable(frame, ConditionalFrame)
    frame:refresh_gens()
    return frame
  end;
})

function ConditionalFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(type(obj.value) == "number", "Error in %s: Missing/invalid property: 'value' must be a number.", where)
end

function ConditionalFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ConditionalFrame;")
end

function ConditionalFrame:takes_count()
  return self._input_count
end

function ConditionalFrame:index2id(index)
  if index < 1 or index > self:takes_count() then return end
  return string.char(index + 96)
end

function ConditionalFrame:id2index(id)
  local index = tonumber(id:byte() - 96)
  if index < 1 or index > self:takes_count() then return end
  return index
end

function ConditionalFrame:take_by_index(index)
  return self:index2id(index), NoKind
end

function ConditionalFrame:take_by_id(id)
  return self:id2index(id), NoKind
end

function ConditionalFrame.gives_count()
  return 1
end

function ConditionalFrame:_give_kind()
  local data = self._data
  local _, value = data:get_row(data:len())
  if tonumber(value) then
    return NumberKind
  elseif value:find("^%s*['\"]") then
    return StringKind
  else
    local index = tonumber(value:match("^%s*v(%d+)") or "")
    if index then
      local input = self._inputs[index]
      return input
         and input.kind
          or NoKind
    end
    return NoKind
  end
end

function ConditionalFrame:give_by_index(_)
  return "result", self:_give_kind()
end

function ConditionalFrame:give_by_id(_)
  return 1, self:_give_kind()
end

function ConditionalFrame:on_connect(prop, from)
  local index = self:id2index(prop)
  if not index then return end
  self._inputs[index] = from
  from:listen(self, prop, self.refresh)
  self:refresh()
end

function ConditionalFrame:on_disconnect(prop)
  local index = self:id2index(prop)
  if not index then return end
  try_invoke(self._inputs[index], "unlisten", self, prop, self.refresh)
  self._inputs[index] = nil
  self:refresh()
end

function ConditionalFrame:refresh()
  local conditions = self._conditions
  local values = {}
  local inputs = self._inputs
  for index = 1, 26 do
    local input = inputs[index]
    values[index] = input and input.value
  end
  local a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z = unpack(values)
  for index = 1, #conditions do
    if conditions[index](a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z) then
      print ("condition: "..index.." succeeded!!!!")
      break
    end
  end
  --for index = 26, 1, -1 do values[index] = nil end
end

function ConditionalFrame:refresh_gens()
  local len = self._data:len()
  for index = 1, len - 1 do
    self:refresh_condition (index)
    self:refresh_value_gen (index)
  end
  self._conditions[len] = default_condition
  self:refresh_value_gen (len)
end

function ConditionalFrame:refresh_condition(index)
  self._conditions[index] = generate_clause(self._data:get_condition(index))
end

function ConditionalFrame:refresh_value_gen(index)
  self._value_gens[index] = generate_clause(self._data:get_value(index))
end

local pad = 2
function ConditionalFrame:_field_info()
  local text_height = love.graphics.getFont():getHeight()
  local row_height  = text_height + 2*pad
  return math.floor((self.size_x - 3*pad)/2), row_height - pad, row_height
end

function ConditionalFrame:_draw_prep_condition(condition, index)
  if not condition:find("[^%s]+") then
    love.graphics.setColor(0.6, 0.6, 0.6)
    if index == self._data:len() then
      condition = "default"
    else
      condition = "..."
    end
  else
    love.graphics.setColor(0.0, 0.0, 0.0)
  end
  return condition
end

function ConditionalFrame._draw_prep_value(_, value, give_kind)
  if not value:find("[^%s]+") then
    love.graphics.setColor(0.6, 0.6, 0.6)
    value = tostring(give_kind.to_shader_value() or "") or ""
  else
    love.graphics.setColor(0.0, 0.0, 0.0)
  end
  return value
end

function ConditionalFrame:draw(size_x, size_y, scale)
  pleasure.push_region(0, 0, size_x, size_y)
  love.graphics.setColor(0.4, 0.4, 0.4)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
  love.graphics.setColor(0.9, 0.9, 0.9)

  love.graphics.setLineStyle("rough")
  local give_kind = self:_give_kind()
  local font = love.graphics.getFont()
  local field_size_x, field_size_y, row_height = self:_field_info()
  for condition, value, index in self._data:rows() do
    local x1 = pad
    local x2 = 2*pad + field_size_x
    local y  = (index - 1)*row_height + pad

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", x1, y, field_size_x, field_size_y)
    love.graphics.rectangle("fill", x2, y, field_size_x, field_size_y)

    self:_draw_prep_condition(condition, index)
    pleasure.push_region(x1, y, field_size_x, field_size_y)
    font_writer.print_aligned(font, condition, pad, pad, "left", "top")
    pleasure.pop_region()

    pleasure.push_region(x2, y, field_size_x, field_size_y)
    self:_draw_prep_value(value, give_kind)
    font_writer.print_aligned(font, value, pad, pad, "left", "top")
    pleasure.pop_region()
  end

  if self:has_focus() then
    pleasure.push_region(self._edit_x, self._edit_y, field_size_x, field_size_y)

    local text = self._edit.text or ""
    if self._edit_column == 1 then
      self:_draw_prep_condition(text, self._edit_row)
    else
      self:_draw_prep_value(text, give_kind)
    end
    love.graphics.setColor(1,0,0,1)
    self._edit.size_x = field_size_x
    self._edit.size_y = field_size_y
    self._edit:draw(self, scale)
    pleasure.pop_region()
  end

  --self._edit:draw(self, scale)
  pleasure.pop_region()
end

function ConditionalFrame:_refresh()
  if self._active_index then
    self._data:set_direct(self._active_index, self._edit.text or "")
    if self._edit_column == 1 then
      self:refresh_condition(self._edit_row)
    else
      self:refresh_value_gen(self._edit_row)
    end
  end
  self:refresh()
end

function ConditionalFrame:mousepressed(mx, my, button)
  self:request_focus()

  local data = self._data

  -- save edit text to field
  self:_refresh()

  -- load field into edit text
  local field_size_x, field_size_y, row_height = self:_field_info()
  local row_index = 1 + math.floor((my - pad)/row_height)
  if row_index < 1 or row_index > data:len() then return end

  local x1 = pad
  local x2 = 2*pad + field_size_x
  local column = mx < x2 and 1 or 0

  local active_index = row_index*2 - column
  self._active_index = active_index

  local text = data:get_direct(active_index)
  self._edit:set_text(text)
  self._edit.size_x = field_size_x
  self._edit.size_y = field_size_y

  local x = column == 1 and x1 or x2
  local y = (row_index - 1)*row_height + pad

  self._edit_x = x
  self._edit_y = y
  self._edit_column = column
  self._edit_row = row_index
  self._edit:mousepressed(mx - x, my - y, button)
end

function ConditionalFrame:mousedragged1(mx, my)
  self._edit:mousedragged1(mx, my)
end

function ConditionalFrame:keypressed(key, scancode, isrepeat)
  if key == "return" then
    self:_refresh()
  else
    self._edit:keypressed(key, scancode, isrepeat)
  end
end

function ConditionalFrame:textinput(text)
  self._edit:textinput(text)
end

function ConditionalFrame:focusgained()
  self._edit.focused = true
end

function ConditionalFrame:focuslost()
  self:refresh()
  self._edit.focused = false
end

function ConditionalFrame.id()
  return "Conditional"
end

function ConditionalFrame:serialize()
  return ([[ConditionalFrame {
    _data = %s;
  }]]):format(self._data:dump())
end


return ConditionalFrame
