local PropertyStore           = require "PropertyStore"

local Toolbox = {
  require "tool.pencil";
  require "tool.eraser";
  require "tool.picker";
  require "tool.circle";
  require "tool.line";
  require "tool.rectangle";
  require "tool.bucket";
}

PropertyStore.set_default("core.graphics", "paint.tool" , Toolbox[1])

return Toolbox
