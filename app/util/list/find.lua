return function (list, item)
  for i = 1, #list do
    if item == list[i] then
      return i
    end
  end
end
