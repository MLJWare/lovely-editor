local function is(x, y)
  return type(x) == "number"
     and type(y) == "number"
end

local tmp_vec2 = {0,0}

return {
  name = "2 Numbers";
  is = is;
  IS_VECTOR = 2;
  to_shader_value = function (x, y)
    if is(x, y) then
      tmp_vec2[1] = x
      tmp_vec2[2] = y
    else
      tmp_vec2[1] = 0
      tmp_vec2[2] = 0
    end
    return tmp_vec2
  end;
}
