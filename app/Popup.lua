local Frame                   = require "Frame"
local assertf                 = require "assertf"
local is                      = require "pleasure.is"

local is_opt = is.opt
local is_table = is.table
local is_number = is.number
local is_metakind = is.metakind

local Popup = {}
Popup.__index = Popup
Popup._kind = ";Popup;"

Popup.frame = setmetatable({}, {
  __index = {
    size_x = 8;
    size_y = 8;
  };
})

setmetatable(Popup, {
  __index = Frame;
  __call  = function (_, view)
    assert(is_table(view), "Popup constructor must be a table.")
    Popup.typecheck(view, "Popup constructor")

    view.scale = view.scale or 1
    setmetatable(view, Popup)

    return view
  end;
})

function Popup.typecheck(obj, where)
  assertf(is_number(obj.pos_x), "Error in %s: Missing/invalid property: 'pos_x' must be a number.", where)
  assertf(is_number(obj.pos_y), "Error in %s: Missing/invalid property: 'pos_y' must be a number.", where)
  assertf(is_opt(obj.frame, Frame.is), "Error in %s: invalid optional property: 'frame' must be a Frame.", where)
end

function Popup.is(obj)
  return is_metakind(obj, ";Popup;")
end

return Popup
