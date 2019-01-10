return function (input)
  if input:find("^-") then
    return "-"..input:gsub("%D+", "")
  else
    return input:gsub("%D+", "")
  end
end
