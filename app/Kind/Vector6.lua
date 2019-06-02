local function is(x, y, z, w, a, b)
  return type(x) == "number"
     and type(y) == "number"
     and type(z) == "number"
     and type(w) == "number"
     and type(a) == "number"
     and type(b) == "number"
end

local tmp_vec6 = {0,0,0,0,0,0}

return {
  is = is;
  IS_VECTOR = 6;
  to_shader_value = function (x, y, z, w, a, b)
    if is(x, y, z, w, a, b) then
      tmp_vec6[1] = x
      tmp_vec6[2] = y
      tmp_vec6[3] = z
      tmp_vec6[4] = w
      tmp_vec6[5] = a
      tmp_vec6[6] = b
    else
      tmp_vec6[1] = 0
      tmp_vec6[2] = 0
      tmp_vec6[3] = 0
      tmp_vec6[4] = 0
      tmp_vec6[5] = 0
      tmp_vec6[6] = 0
    end
    return tmp_vec6
  end;
}
