local vec2                    = require "linear-algebra.Vector2"
local Frame                   = require "Frame"
local IOs                     = require "IOs"
local ImagePacket             = require "packet.Image"
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
  {id = "code",  kind = string};
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
    local success, data = pcall(love.graphics.newShader, from())
    self.shader_in = success and data or nil
    self:refresh()
  end
end

function ShaderFrame:on_disconnect(prop)
  if prop == "image" then
    try_invoke(self.image_in, "unlisten", self)
    self.image_in = nil
    self:refresh()
  elseif prop == "code" then
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

local _paste_self = nil
local function _paste()
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  local shader_in = _paste_self.shader_in
  if shader_in then
    love.graphics.setShader(shader_in)
  end
  love.graphics.draw(_paste_self.image_in.canvas)
  love.graphics.setShader()
end

function ShaderFrame:refresh()
  if not self.image then return end
  _paste_self = self
  self.image.canvas:renderTo(_paste)
  _paste_self = nil
  self.image:inform()
end

function ShaderFrame:draw(_, scale)
  local packet = self.image_in
  if not packet then return end

  if not self.image then return end
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.canvas, 0, 0, 0, scale, scale)
end

return ShaderFrame