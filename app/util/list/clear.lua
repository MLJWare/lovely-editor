return function (list)
  for i = #list, 1, -1 do
    list[i] = nil
  end
end