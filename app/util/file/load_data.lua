local unicode                 = require "unicode"

local function file_extension(filename)
  return (filename or ""):match("[^.]*$") or ""
end

local function try_create_image_data (filedata, filename)
  return love.image.newImageData(love.filesystem.newFileData(filedata, filename))
end

return function (file)
  if not file:open("r") then return end
  local raw_data = file:read()
  file:close()

  local filename = file:getFilename()
  local ext = file_extension(filename)
  if ext == "png" then
    local success, data = pcall(try_create_image_data, raw_data, filename)
    return success and data or nil, "image"
  elseif unicode.is_valid(raw_data) then
    return raw_data, "text"
  end
end
