local TextBuffer = {}
TextBuffer.__index = TextBuffer

TextBuffer._kind = ";TextBuffer;"

setmetatable(TextBuffer, {
  __call = function (_, buffer)
    assert(type(buffer) == "table", "TextBuffer constructor must be a table.")
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
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";TextBuffer;")
end

function TextBuffer:get(lineNumber)
  return self[lineNumber] or ""
end

function TextBuffer:set(lineNumber, text)
  self._dirty = true
  text = (text or ""):gsub("\t", "  "):gsub("\r", "")
  self[lineNumber] = text
end

function TextBuffer:add(lineNumber, text)
  self._dirty = true
  lineNumber = math.max(1, math.min(lineNumber, #self + 1))
  table.insert(self, lineNumber, text)
end

function TextBuffer:remove(lineNumber)
  self._dirty = true
  return table.remove(self, lineNumber)
end

function TextBuffer:line_count()
  return #self
end

function TextBuffer:lines(from, to)
  if not (from or to) then return ipairs(self) end
  local i = (from or 1) - 1
  to = to or math.huge
  return function ()
    if i <= to then
      i = i + 1
      local v = self[i]
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
    self[i] = nil
  end
  self[1] = ""
end

return TextBuffer