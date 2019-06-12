local Action = {}
Action.__index = Action

function Action:undo(buffer)
  -- TODO
end

function Action:redo(buffer)
  -- TODO
end

--[[
format: {
  line_nr
  , removed_count, ...removed_strings...
  , inserted_count, ...inserted_strings...
}

-- example: newline at end of line 3 (creates new line 4)
{4, 0, 1, ""}

-- example: newline between "foo" and "baz" in line 2 "foobaz"
{2, 1, "foobaz", 2, "foo", "baz"}

-- example: replace "ello" with "i" in line 3 "Hello, World"
{3, 1, "Hello, World", 1, "Hi, World"}
--]]

function Action.apply(buffer, line, remove_count, ...)
  for i = 0, remove_count do
    -- TODO
  end
  return setmetatable({line, remove_count, ...}, Action)
end

return Action
