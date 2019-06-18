local fail_clause             = require "fn.fail"
local sandbox                 = require "util.sandbox"

return function (code)
  if not code:find("%S") then return fail_clause end

  local made_fn, fn = sandbox(([[
  return function (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z)
    return %s
  end
  ]]):format(code), {})

  if not made_fn then return fail_clause end

  return function (...)
    local success, result = pcall(fn, ...)
    if success then
      return result
    end
  end
end
