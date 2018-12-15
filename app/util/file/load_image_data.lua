local function file_extension(file)
  return (file:getFilename() or ""):match("[^.]*$") or ""
end

local function _load_image_data (file)
  if file_extension(file) ~= "png" then return end
  if not file:open("r") then return end
  local data = file:read()
  file:close()
  return love.image.newImageData(love.filesystem.newFileData(data, file:getFilename()))
end

return function (file)
  local success, data = pcall(_load_image_data, file)
  return success and data or nil
end