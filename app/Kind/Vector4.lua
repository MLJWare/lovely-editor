local default = {0,0,0,0}

local function is(data)
  return type(data) == "table"
     and #data == 4
     and type(data[1]) == "number"
     and type(data[2]) == "number"
     and type(data[3]) == "number"
     and type(data[4]) == "number"
end

return {
  is = is;
  to_shader_value = function (data)
    return is(data) and data or default
  end;
}
