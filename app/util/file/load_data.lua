local function file_extension(file)
  return (file:getFilename() or ""):match("[^.]*$") or ""
end

local function _load_image_data (file)
  if not file:open("r") then return end
  local data = file:read()
  file:close()
  return love.image.newImageData(love.filesystem.newFileData(data, file:getFilename()))
end

local function _load_text_data (file)
  if not file:open("r") then return end
  local data = file:read()
  file:close()
  return data
end

return function (file)
  local ext = file_extension(file)
  if ext == "png" then
    local success, data = pcall(_load_image_data, file)
    return success and data or nil, "image"
  else
    local success, data = pcall(_load_text_data, file)
    return success and data or nil, "text"
  end
end