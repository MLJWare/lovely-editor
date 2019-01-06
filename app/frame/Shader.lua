local vec2                    = require "linear-algebra.Vector2"
local Frame                   = require "Frame"
local list_clear              = require "util.list.clear"
local list_find               = require "util.list.find"
local IOs                     = require "IOs"
local ImagePacket             = require "packet.Image"
local NumberPacket            = require "packet.Number"
local StringPacket            = require "packet.String"
local try_invoke              = require "pleasure.try".invoke

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
    frame._uniforms_in    = {}

    frame._uniform_ids    = {}
    frame._uniform_ids2   = {}
    frame._uniform_kinds  = {}
    frame._uniform_kinds2 = {}

    setmetatable(frame, ShaderFrame)

    return frame
  end;
})

--ShaderFrame.takes = IOs{
--  {id = "image", kind = ImagePacket};
--  {id = "code",  kind = StringPacket};
--}

function ShaderFrame:takes_count()
  return 2 + #self._uniform_ids
end

function ShaderFrame:take_by_index(index)
  if index == 1 then
    return "image", ImagePacket
  elseif index == 2 then
    return "code", StringPacket
  else
    index = index - 2
    return self._uniform_ids[index], self._uniform_kinds[index]
  end
end

function ShaderFrame:take_by_id(id)
  if id == "image" then
    return 1, ImagePacket
  elseif id == "code" then
    return 2, StringPacket
  else
    local uniform_ids = self._uniform_ids
    for i = 1, #uniform_ids do
      if uniform_ids[i] == id then
        return i + 2, self._uniform_kinds[i]
      end
    end
  end
end

ShaderFrame.gives = IOs{
  {id = "image", kind = ImagePacket};
}

function ShaderFrame:on_connect(prop, from)
  if prop == "image" then
    self.image_in = from
    from:listen(self, self.refresh)
    self.image    = from:clone()
    self.size:setn(from.value:getDimensions())
    self:refresh()
  elseif prop == "code" then
    self.code_in = from
    from:listen(self, self.refresh_shader)
    self:refresh_shader()
  else
    local uniform_ids = self._uniform_ids
    local index = list_find(uniform_ids, prop)
    if not index then return end
    self._uniforms_in[prop] = from
    from:listen(self, self.refresh_uniforms)
    self:refresh_uniforms()
  end
end

function ShaderFrame:on_disconnect(prop)
  if prop == "image" then
    try_invoke(self.image_in, "unlisten", self, self.refresh)
    self.image_in = nil
    self:refresh()
  elseif prop == "code" then
    try_invoke(self.code_in, "unlisten", self, self.refresh_shader)
    self.code_in   = nil
    self.shader_in = nil
    self:refresh()
  else
    try_invoke(self._uniforms_in[prop], "unlisten", self, self.refresh_uniforms)
    self._uniforms_in[prop] = nil
    self:refresh_uniforms()
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
  return self.image.value:newImageData():encode("png")
end

function ShaderFrame:refresh()
  if not self.image then return end
  local cv = love.graphics.getCanvas()

  love.graphics.setCanvas(self.image.value)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  local shader_in = self.shader_in
  if shader_in then
    love.graphics.setShader(shader_in)
  end
  local image = self.image_in
  if image then
    love.graphics.draw(image.value)
  end
  love.graphics.setShader()
  love.graphics.setCanvas(cv)
  self.image:inform()
end

function ShaderFrame:_set_uniform(prop, from)
  local shader = self.shader_in
  if not (shader and shader:hasUniform(prop)) then return end
  local value
  if from then
    value = from.value
  else
    local kind = self._uniform_kinds[prop]
    if not kind then return end
    value = kind.default_raw_value()
  end
  shader:send(prop, value)
end

function ShaderFrame:refresh_uniforms()
  local uniform_ids   = self._uniform_ids
  local uniforms_in   = self._uniforms_in

  for index = 1, #uniform_ids do
    local prop = uniform_ids[index]
    local from = uniforms_in[prop]
    self:_set_uniform(prop, from)
  end
  self:refresh()
end

function ShaderFrame:refresh_shader()
  local code = self.code_in
  if not code then return end
  code = code.value
  if not code then return end
  local success, data = pcall(love.graphics.newShader, code)
  self.shader_in = success and data or nil
  if success then
    self:detect_uniforms(code)
  end
  self:refresh()
end

local known_uniform_kinds = {
  ["float"] = NumberPacket; --TODO make "FloatPacket"
  ["Image"] = ImagePacket;
}

function ShaderFrame:detect_uniforms(code)
  local uniform_ids2   = self._uniform_ids2
  local uniform_kinds2 = self._uniform_kinds2

  for statement in code:gmatch "[^;]+" do
    local words = statement:gmatch"[a-zA-Z0-9_,]+"
    for word in words do
      if word ~= "uniform" and word ~= "extern" then goto next_statement end
      local kind = known_uniform_kinds[ words() ]
      if not kind then goto next_statement end
      for id in words():gmatch"[a-zA-Z0-9_]+" do
        local index = #uniform_ids2 + 1
        uniform_ids2  [index] = id
        uniform_kinds2[index] = kind
      end
    end
    ::next_statement::
  end

  local uniform_ids = self._uniform_ids
  local uniform_kinds = self._uniform_kinds

  for index = #uniform_ids, 1, -1 do
    local id = uniform_ids[index]
    local found_index = list_find(uniform_ids2, id)
    if not found_index
    or uniform_kinds[index] ~= uniform_kinds2[found_index] then
      self:on_disconnect(id)
    end
  end

  list_clear(uniform_ids)
  list_clear(uniform_kinds)

  self._uniform_ids    = uniform_ids2
  self._uniform_ids2   = uniform_ids
  self._uniform_kinds  = uniform_kinds2
  self._uniform_kinds2 = uniform_kinds
end

function ShaderFrame:draw(_, scale)
  local packet = self.image_in
  if not packet then return end

  if not self.image then return end

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.value, 0, 0, 0, scale, scale)
end

return ShaderFrame