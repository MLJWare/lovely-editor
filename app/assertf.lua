return function (condition, error_msg, ...)
  if not condition then
    error(error_msg:format(...), 2)
  end
end