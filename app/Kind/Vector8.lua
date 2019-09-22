local function is(x, y, z, w, a, b, c, d)
  return type(x) == "number"
     and type(y) == "number"
     and type(z) == "number"
     and type(w) == "number"
     and type(a) == "number"
     and type(b) == "number"
     and type(c) == "number"
     and type(d) == "number"
end

local tmp_vec8 = {0,0,0,0,0,0,0,0}

return {
  name = "8 Numbers";
  is = is;
  IS_VECTOR = 8;
  to_shader_value = function (x, y, z, w, a, b, c, d)
    if is(x, y, z, w, a, b, c, d) then
      tmp_vec8[1] = x
      tmp_vec8[2] = y
      tmp_vec8[3] = z
      tmp_vec8[4] = w
      tmp_vec8[5] = a
      tmp_vec8[6] = b
      tmp_vec8[7] = c
      tmp_vec8[8] = d
    else
      tmp_vec8[1] = 0
      tmp_vec8[2] = 0
      tmp_vec8[3] = 0
      tmp_vec8[4] = 0
      tmp_vec8[5] = 0
      tmp_vec8[6] = 0
      tmp_vec8[7] = 0
      tmp_vec8[8] = 0
    end
    return tmp_vec8
  end;
}
