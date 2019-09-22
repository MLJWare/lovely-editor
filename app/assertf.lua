return function (condition, error_msg, a, b, c, d)
  if condition then return end
  error(error_msg:format(a, b, c, d), 2)
end
