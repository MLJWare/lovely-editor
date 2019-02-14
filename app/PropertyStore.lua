local ensure                  = require "ensure"
local pack_color              = require "util.color.pack"

local P = {}

local _current = {}
local _default = {}

local function _get(data, domain, property)
  local stored = data[domain]
  return stored and stored[property]
end

local function _set(data, domain, property, value)
  ensure(data, domain)[property] = value
end

function P.set(domain, property, value)
  assert(domain, "Missing first argument, 'domain', of `PropertyStore.set`")
  assert(property, "Missing second argument, 'property', of `PropertyStore.set`")
  _set(_current, domain, property, value)
end

-- QUESTION should this function be globally accessable?
function P.set_default(domain, property, value)
  assert(domain, "Missing first argument, 'domain', of `PropertyStore.set_default`")
  assert(property, "Missing second argument, 'property', of `PropertyStore.set_default`")
  _set(_default, domain, property, value)

  if not _get(_current, domain, property) then
    _set(_current, domain, property, value)
  end
end

function P.get(domain, property)
  assert(domain, "Missing first argument, 'domain', of `PropertyStore.get`")
  assert(property, "Missing second argument, 'property', of `PropertyStore.get`")
  return _get(_current, domain, property)
      or _get(_default, domain, property)
end

-- setup initial properties
do
  P.set_default("core.graphics", "paint.color", pack_color(1, 1, 1, 1))
end

return P
