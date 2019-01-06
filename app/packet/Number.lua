local Packet = require "Packet"
local assertf = require "assertf"
local NumberPacket = {}
NumberPacket.__index = NumberPacket

NumberPacket._kind = ";NumberPacket;Packet;"

setmetatable(NumberPacket, {
  __index = Packet;
  __call = function (_, value)
    assert(type(value) == "table", "NumberPacket constructor must be a table.")
    NumberPacket.typecheck(value, "NumberPacket constructor")
    setmetatable(Packet(value), NumberPacket)
    return value
  end;
})

function NumberPacket.typecheck(obj, where)
  Packet.typecheck(obj, where)
  assertf(type(obj.value) == "number", "Error in %s: Missing/invalid property: 'value' must be a number.", where)
end

function NumberPacket.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";NumberPacket;")
end

function NumberPacket.default_raw_value()
  return 0
end

return NumberPacket
