local function is (data)
  return type(data) == "number"
end

return {
  name = "Number";
  is = is;
  IS_VECTOR = 1;
  to_shader_value = function (data)
    return is(data) and data or 0
  end;
}
