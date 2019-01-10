return function (untrustedCode, env, ...)
  env = env or {}
  local untrustedFn, msg = load(untrustedCode, nil, "t", env)
  if not untrustedFn then return nil, msg end
  local success, data = pcall(untrustedFn, ...)
  return success and env, data
end
