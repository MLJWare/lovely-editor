local function is (data)
  return type(data) == "string"
end

return {
  name = "String";
  is = is;
  to_shader_value = function (data)
    return is(data) and data or ""
  end;
}
