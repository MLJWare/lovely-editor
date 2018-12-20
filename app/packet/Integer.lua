local Packet = require "Packet"
local assertf = require "assertf"
local IntegerPacket = {}
IntegerPacket.__index = IntegerPacket

IntegerPacket._kind = ";IntegerPacket;Packet;"

setmetatable(IntegerPacket, {
  __index = Packet;
  __call = function (_, value)
    assert(type(value) == "table", "IntegerPacket constructor must be a table.")
    IntegerPacket.typecheck(value, "IntegerPacket constructor")
    setmetatable(Packet(value), IntegerPacket)
    return value
  end;
})

function IntegerPacket.typecheck(obj, where)
  Packet.typecheck(obj, where)
  assertf(type(obj.value) == "number" and obj.value%1==0, "Error in %s: Missing/invalid property: 'value' must be an integer.", where)
end

function IntegerPacket.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";IntegerPacket;")
end

return IntegerPacket