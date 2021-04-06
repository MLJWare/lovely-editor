local is = require "pleasure.is"
local is_number = is.number
local is_table_of = is.table_of

return {
  name = "Packet of Numbers";
  is = function (v) return is_table_of(v, is_number) end;
  to_shader_value = function () return 0 end;
}
