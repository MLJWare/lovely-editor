local function is(x, y, z)
  return type(x) == "number"
     and type(y) == "number"
     and type(z) == "number"
end

local tmp_vec3 = {0,0,0}

return {
  is = is;
  IS_VECTOR = 3;
  to_shader_value = function (x, y, z)
    if is(x, y, z) then
      tmp_vec3[1] = x
      tmp_vec3[2] = y
      tmp_vec3[3] = z
    else
      tmp_vec3[1] = 0
      tmp_vec3[2] = 0
      tmp_vec3[3] = 0
    end
    return tmp_vec3
  end;
}
