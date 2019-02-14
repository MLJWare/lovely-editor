local pack_color              = require "util.color.pack"

local sandbox = require "util.sandbox"

local function setup_settings(default, user)
  for key, user_value in pairs(user) do
    local default_value = default[key]
    if not default_value then
      default[key] = user_value
    else
      local default_type = type(default_value)
      local user_type    = type(user_value)
      if default_type == user_type then
        if default_type == "table" then
          default[key] = setup_settings(default_value, user_value)
        else
          default[key] = user_value
        end
      end
    end
  end
  return default
end

local settings = {
  style = {
    transparency = {
      pattern = "checker";
      color  = pack_color(0.15, 0.15, 0.15, 1.0);
      color2 = pack_color(0.05, 0.05, 0.05, 1.0);
      scale  = 32;
    };
  };
}

do
  local code = love.filesystem.read("config/settings.lua")
  local success, user_settings = sandbox(code or "")
  if success and type(user_settings) == "table" then
    setup_settings(settings, user_settings)
  end
end

return settings
