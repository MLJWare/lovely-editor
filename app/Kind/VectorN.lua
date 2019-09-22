local function is(x, y, z, w, a, b, c, d)
  return type(x) == "number"
    and y == nil and 1
    or( type(y) == "number"
      and z == nil and 2
      or( type(z) == "number"
        and w == nil and 3
        or( type(w) == "number"
          and a == nil and 4
          or( type(a) == "number"
            and b == nil and 5
            or( type(b) == "number"
              and c == nil and 6
              or( type(c) == "number"
                and d == nil and 7
                or( type(d) == "number" and 8)))))))
end

local tmp_vec8 = {0,0,0,0,0,0,0,0}

return {
  name = "Sequence of Numbers";
  is = is;
  IS_VECTOR = 8;
  to_shader_value = function (x, y, z, w, a, b, c, d)
    if is(x, y, z, w, a, b, c, d) then
      tmp_vec8[1] = x
      tmp_vec8[2] = y or 0
      tmp_vec8[3] = z or 0
      tmp_vec8[4] = w or 0
      tmp_vec8[5] = a or 0
      tmp_vec8[6] = b or 0
      tmp_vec8[7] = c or 0
      tmp_vec8[8] = d or 0
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
