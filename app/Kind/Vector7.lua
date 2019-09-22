local function is(x, y, z, w, a, b, c)
  return type(x) == "number"
     and type(y) == "number"
     and type(z) == "number"
     and type(w) == "number"
     and type(a) == "number"
     and type(b) == "number"
     and type(c) == "number"
end

local tmp_vec7 = {0,0,0,0,0,0,0}

return {
  name = "7 Numbers";
  is = is;
  IS_VECTOR = 7;
  to_shader_value = function (x, y, z, w, a, b, c)
    if is(x, y, z, w, a, b, c) then
      tmp_vec7[1] = x
      tmp_vec7[2] = y
      tmp_vec7[3] = z
      tmp_vec7[4] = w
      tmp_vec7[5] = a
      tmp_vec7[6] = b
      tmp_vec7[7] = c
    else
      tmp_vec7[1] = 0
      tmp_vec7[2] = 0
      tmp_vec7[3] = 0
      tmp_vec7[4] = 0
      tmp_vec7[5] = 0
      tmp_vec7[6] = 0
      tmp_vec7[7] = 0
    end
    return tmp_vec7
  end;
}
