local assertf                 = require "assertf"
local is_callable             = require "pleasure.is".callable

local Signal = {}
Signal.__index = Signal

Signal._kind = ";Signal;"

setmetatable(Signal, {
  __call = function (_, signal)
    assert(type(signal) == "table", "Signal constructor must be a table.")
    Signal.typecheck(signal, "Signal constructor")
    setmetatable(signal, Signal)
    signal.listeners = {}
    return signal
  end;
})

function Signal.typecheck(obj, where)
  local kind  = obj.kind
  assertf(is_callable(obj.on_connect), "Error in %s: Missing/invalid property: 'on_connect' must be callable.", where)
  assertf(type(kind) == "table", "Error in %s: Missing/invalid property: 'kind' must be a table representing a Kind.", where)
  assertf(is_callable(kind.is), "Error in %s: Missing/invalid property: 'kind' must be a table representing a Kind ('kind.is' should be callable).", where)
  assertf(is_callable(kind.to_shader_value), "Error in %s: Missing/invalid property: 'kind' must be a table representing a Kind ('kind.to_shader_value' should be callable).", where)
end

function Signal.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";Signal;")
end

function Signal:listen(listener, prop, callback)
  if not (listener and prop and callback) then return end
  local listeners = self.listeners
  local len = #listeners
  listeners[len + 1] = listener
  listeners[len + 2] = prop
  listeners[len + 3] = callback
end

function Signal:unlisten(listener, prop, callback)
  local listeners = self.listeners
  for i = #listeners, 1, -3 do
    local callback2 = listeners[i    ]
    local prop2     = listeners[i - 1]
    local listener2 = listeners[i - 2]
    if listener == listener2
    and prop == prop2
     and callback == callback2 then
      table.remove(listeners, i)     -- remove callback
      table.remove(listeners, i - 1) -- remove prop
      table.remove(listeners, i - 2) -- remove listener
      break
    end
  end
end

function Signal:inform(data)
  local listeners = self.listeners
  for i = 1, #listeners, 3 do
    listeners[i + 2](listeners[i], data, listeners[i + 1])
  end
end

return Signal
