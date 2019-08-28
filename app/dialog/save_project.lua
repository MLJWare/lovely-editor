local app                     = require "app"
local SaveFileFrame           = require "frame.SaveFile"

return SaveFileFrame {
  action = function (_, filename)
    local data = app.project:serialize()
    if filename:find("%.lp_raw$") then
      return data
    end
    return love.data.compress("string", "lz4", data)
  end;
}
