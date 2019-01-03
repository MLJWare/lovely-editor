local vec2                    = require "linear-algebra.Vector2"
local Frame                   = require "Frame"
local IOs                     = require "IOs"
local ImagePacket             = require "packet.Image"
local StringPacket            = require "packet.String"
local try_invoke              = require "pleasure.try".invoke
--local assertf                 = require "assertf"

local ShaderFrame = {}
ShaderFrame.__index = ShaderFrame

ShaderFrame._kind = ";ShaderFrame;Frame;"

setmetatable(ShaderFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ShaderFrame constructor must be a table.")
    if not frame.size then
      frame.size = vec2(16, 32)
    end

    ShaderFrame.typecheck(frame, "ShaderFrame constructor")
    setmetatable(frame, ShaderFrame)
    return frame
  end;
})

ShaderFrame.takes = IOs{
  {id = "image", kind = ImagePacket};
  {id = "code",  kind = StringPacket};
}
ShaderFrame.gives = IOs{
  {id = "image", kind = ImagePacket};
}

function ShaderFrame:on_connect(prop, from)
  if prop == "image" then
    self.image_in = from
    from:listen(self, self.refresh)
    self.image    = from:clone()
    self.size:setn(from.canvas:getDimensions())
    self:refresh()
  elseif prop == "code" then
    self.code_in = from
    from:listen(self, self.refresh_shader)
    self:refresh_shader()
  end
end

function ShaderFrame:on_disconnect(prop)
  if prop == "image" then
    try_invoke(self.image_in, "unlisten", self)
    self.image_in = nil
    self:refresh()
  elseif prop == "code" then
    try_invoke(self.code_in, "unlisten", self)
    self.code_in   = nil
    self.shader_in = nil
    self:refresh()
  end
end

function ShaderFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
  --assertf(Shader.is(obj.color), "Error in %s: Missing/invalid property: 'color' must be a Shader.", where)
end

function ShaderFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ShaderFrame;")
end

function ShaderFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.image and self.on_save or nil
  end
end

function ShaderFrame:on_save()
  return self.image.canvas:newImageData():encode("png")
end

function ShaderFrame:refresh()
  if not self.image then return end
  local cv = love.graphics.getCanvas()

  love.graphics.setCanvas(self.image.canvas)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  local shader_in = self.shader_in
  if shader_in then
    love.graphics.setShader(shader_in)
  end
  local image = self.image_in
  if image then
    love.graphics.draw(image.canvas)
  end
  love.graphics.setShader()
  love.graphics.setCanvas(cv)
  self.image:inform()
end

function ShaderFrame:refresh_shader()
  local code = self.code_in
  if not code then return end
  local success, data = pcall(love.graphics.newShader, code.value)
  self.shader_in = success and data or nil
  self:refresh()
end

function ShaderFrame:draw(_, scale)
  local packet = self.image_in
  if not packet then return end

  if not self.image then return end

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.canvas, 0, 0, 0, scale, scale)
end

return ShaderFrame