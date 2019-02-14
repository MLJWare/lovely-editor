local function is(x, y, z, w)
  return type(x) == "number"
     and type(y) == "number"
     and type(z) == "number"
     and type(w) == "number"
end

local tmp_vec4 = {0,0,0,0}

return {
  is = is;
  to_shader_value = function (x, y, z, w)
    if is(x, y, z, w) then
      tmp_vec4[1] = x
      tmp_vec4[2] = y
      tmp_vec4[3] = z
      tmp_vec4[4] = w
    else
      tmp_vec4[1] = 0
      tmp_vec4[2] = 0
      tmp_vec4[3] = 0
      tmp_vec4[4] = 0
    end
    return tmp_vec4
  end;
}
