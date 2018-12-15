return function (list, element)
  for index = 1, #list do
    if element == list[index] then
      table.remove(list, index)
      return index
    end
  end
end