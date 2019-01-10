return function (untrustedCode, env, ...)
  env = env or {}
  local untrustedFn, msg = load(untrustedCode, nil, "t", env)
  if not untrustedFn then return nil, msg, env end
  local success, data = pcall(untrustedFn, ...)
  if success then
    return data, env
  else
    return false, data
  end
end
