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
end

function Packet.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";Packet;")
end

function Packet:listen(listener, callback)
  if not (listener and callback) then return end
  local listeners = self.listeners
  local len = #listeners
  listeners[len + 1] = listener
  listeners[len + 2] = callback
end

function Packet:unlisten(listener, callback)
  local listeners = self.listeners
  for i = #listeners, 1, -2 do
    local callback2 = listeners[i    ]
    local listener2 = listeners[i - 1]

    if listener == listener2
    and  callback == callback2 then
      table.remove(listeners, i)
      table.remove(listeners, i - 1)
      break
    end
  end
end

function Packet:inform()
  local listeners = self.listeners
  for i = 1, #listeners, 2 do
    listeners[i + 1](listeners[i], self)
  end
end

return Packet
