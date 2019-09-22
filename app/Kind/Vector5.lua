local function is(x, y, z, w, a)
  return type(x) == "number"
     and type(y) == "number"
     and type(z) == "number"
     and type(w) == "number"
     and type(a) == "number"
end

local tmp_vec5 = {0,0,0,0,0}

return {
  name = "5 Numbers";
  is = is;
  IS_VECTOR = 5;
  to_shader_value = function (x, y, z, w, a)
    if is(x, y, z, w, a) then
      tmp_vec5[1] = x
      tmp_vec5[2] = y
      tmp_vec5[3] = z
      tmp_vec5[4] = w
      tmp_vec5[5] = a
    else
      tmp_vec5[1] = 0
      tmp_vec5[2] = 0
      tmp_vec5[3] = 0
      tmp_vec5[4] = 0
      tmp_vec5[5] = 0
    end
    return tmp_vec5
  end;
}
