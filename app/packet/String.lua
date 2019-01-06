local Packet = require "Packet"
local assertf = require "assertf"

local StringPacket = {}
StringPacket.__index = StringPacket

StringPacket._kind = ";StringPacket;Packet;"

setmetatable(StringPacket, {
  __index = Packet;
  __call = function (_, value)
    assert(type(value) == "table", "StringPacket constructor must be a table.")
    StringPacket.typecheck(value, "StringPacket constructor")
    setmetatable(Packet(value), StringPacket)
    return value
  end;
})

function StringPacket.typecheck(obj, where)
  Packet.typecheck(obj, where)
  assertf(type(obj.value) == "string", "Error in %s: Missing/invalid property: 'value' must be a string.", where)
end

function StringPacket.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";StringPacket;")
end

function StringPacket.default_raw_value()
  return ""
end

return StringPacket