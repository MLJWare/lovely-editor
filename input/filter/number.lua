return function (input)
  if input:find("^-") then
    return "-"..input:gsub("([^0-9.]+)", ""):match("(%d*%.?%d*)")
  else
    return input:gsub("([^0-9.]+)", ""):match("(%d*%.?%d*)")
  end
end
