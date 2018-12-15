local vec2    = require "linear-algebra.Vector2"
local Frame   = require "Frame"
local assertf = require "assertf"

local Popup = {}
Popup.__index = Popup

Popup._kind = ";Popup;"

Popup.frame = setmetatable({}, {
  __index = {size = vec2(8)};
})

setmetatable(Popup, {
  __index = Frame;
  __call  = function (_, view)
    assert(type(view) == "table", "Popup constructor must be a table.")
    Popup.typecheck(view, "Popup constructor")

    view.scale = view.scale or 1
    setmetatable(view, Popup)

    return view
  end;
})

function Popup.typecheck(obj, where)
  assertf(vec2.is(obj.pos), "Error in %s: Missing/invalid property: 'pos' must be a Vector2.", where)
  assertf(not obj.frame or Frame.is(obj.frame), "Error in %s: invalid optional property: 'frame' must be a Frame.", where)
end

function Popup.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";Popup;")
end

return Popup