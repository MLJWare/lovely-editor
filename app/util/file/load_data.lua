local unicode                 = require "unicode"
local try_create_project      = require "internal.try_create_project"

local function file_extension(filename)
  return (filename or ""):match("[^.]*$") or ""
end

local function try_create_image_data (filedata)
  return love.image.newImageData(filedata)
end

return function (filename, filedata)
  if not filedata then return end
  local ext = file_extension(filename)
  if ext == "png" then
    local success, data = pcall(try_create_image_data, filedata)
    return success and data or nil, "image"
  elseif ext == "lp" or ext == "lp_raw" then
    local success, data = pcall(try_create_project, filedata, filename)
    return success and data or nil, "project"
  else
    local string_data = filedata:getString()
    if unicode.is_valid(string_data) then
      return string_data, "text"
    end
  end
end
