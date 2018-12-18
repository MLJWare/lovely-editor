local vec2                    = require "linear-algebra.Vector2"
local Frame                   = require "Frame"
local ImagePacket             = require "packet.Image"
local IOs                     = require "IOs"
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
  {id = "code",  kind = string};
}
ShaderFrame.gives = IOs{
  {id = "image", kind = ImagePacket};
}

function ShaderFrame:on_connect(prop, from)
  if prop == "image" then
    self.image_in = from
    self.image    = ImagePacket{
      data = from.data:clone();
    }
    self.size:setn(from.data:getDimensions())
  elseif prop == "code" then
    local success, data = pcall(love.graphics.newShader, from())
    print(from)
    self.shader_in = success and data or nil
  end
end

function ShaderFrame:on_disconnect(prop)
  if prop == "image" then
    self.image_in = nil
  elseif prop == "code" then
    self.shader_in = nil
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

function ShaderFrame:draw(size, scale)
  local packet = self.image_in
  if not packet then return end

  love.graphics.setColor(1, 1, 1)
  if self.shader_in then
    local shader = love.graphics.getShader()
    love.graphics.setShader(self.shader_in)
    love.graphics.draw(packet.image, 0, 0, 0, scale, scale)
    love.graphics.setShader(shader)
  else
    love.graphics.draw(packet.image, 0, 0, 0, scale, scale)
  end
end

function ShaderFrame.mousepressed(_, mx, my)
  print(mx, my)
end

return ShaderFrame