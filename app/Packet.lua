local Packet = {}
Packet.__index = Packet

Packet._kind = ";Packet;"

setmetatable(Packet, {
  __call = function (_, packet)
    assert(type(packet) == "table", "Packet constructor must be a table.")
    Packet.typecheck(packet, "Packet constructor")
    setmetatable(packet, Packet)
    packet.listeners = {}
    return packet
  end;
})

function Packet.typecheck(obj, where)
  -- assertf(???, "Error in %s: Missing/invalid property: '???' must be a ???.", where)
end

function Packet.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";Packet;")
end

function Packet:listen(listener, callback)
  self.listeners[listener] = callback
end

function Packet:unlisten(listener)
  self.listeners[listener] = nil
end

function Packet:inform()
  for listener, callback in ipairs(self.listeners) do
    callback(listener, self)
  end
end

return Packet