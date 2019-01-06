local filler = love.graphics.newImage(love.image.newImageData(1,1))

return function (shader, x, y, width,height)
  love.graphics.setShader(shader)
  love.graphics.draw(filler, x, y, 0, width, height)
  love.graphics.setShader()
end
