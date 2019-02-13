local app                     = require "app"
local vec2                    = require "linear-algebra.Vector2"
local Frame                   = require "Frame"
local list_clear              = require "util.list.clear"
local list_find               = require "util.list.find"
local IOs                     = require "IOs"
local ImagePacket             = require "packet.Image"
local Signal                  = require "Signal"
local ImageKind               = require "Kind.Image"
local NumberKind              = require "Kind.Number"
local StringKind              = require "Kind.String"
local try_invoke              = require "pleasure.try".invoke

local ShaderFrame = {}
ShaderFrame.__index = ShaderFrame

ShaderFrame._kind = ";ShaderFrame;Frame;"

local default_size_x = 16
local default_size_y = 32

setmetatable(ShaderFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ShaderFrame constructor must be a table.")
    if not frame.size then
      frame.size = vec2(default_size_x, default_size_y)
    end

    ShaderFrame.typecheck(frame, "ShaderFrame constructor")

    frame.signal_out = Signal {
      kind = ImageKind;
    }

    frame.image = ImagePacket {
      value = love.graphics.newCanvas(default_size_x, default_size_y);
    }

    frame._uniforms_in    = {}

    frame._uniform_ids    = {}
    frame._uniform_ids2   = {}
    frame._uniform_kinds  = {}
    frame._uniform_kinds2 = {}
    frame._uniform_kind_by_id = {}

    setmetatable(frame, ShaderFrame)

    return frame
  end;
})

function ShaderFrame:takes_count()
  return 2 + #self._uniform_ids
end

function ShaderFrame:take_by_index(index)
  if index == 1 then
    return "image", ImageKind
  elseif index == 2 then
    return "code", StringKind
  else
    index = index - 2
    return self._uniform_ids[index], self._uniform_kinds[index]
  end
end

function ShaderFrame:take_by_id(id)
  if id == "image" then
    return 1, ImageKind
  elseif id == "code" then
    return 2, StringKind
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
  {id = "signal_out", kind = ImageKind};
}

function ShaderFrame:on_connect(prop, from, data)
  if prop == "image" then
    self.signal_image = from
    from:listen(self, prop, self.refresh)
    self:refresh(data)
  elseif prop == "code" then
    self.signal_code = from
    from:listen(self, prop, self.refresh_shader)
    self:refresh_shader(data)
  else
    self._uniforms_in [prop] = from
    from:listen(self, prop, self.refresh_uniform)
    self:refresh_uniform(data, prop)
  end
end

function ShaderFrame:on_disconnect(prop)
  if prop == "image" then
    try_invoke(self.signal_image, "unlisten", self, prop, self.refresh)
    self.signal_image = nil
    self:refresh(nil)
  elseif prop == "code" then
    try_invoke(self.signal_code, "unlisten", self, prop, self.refresh_shader)
    self.signal_code = nil
    self.shader_in = nil
    self:refresh(nil)
  else
    try_invoke(self._uniforms_in[prop], "unlisten", self, prop, self.refresh_uniform)
    self._uniforms_in[prop] = nil
    self:refresh_uniform(nil, prop)
  end
end

function ShaderFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ShaderFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ShaderFrame;")
end

function ShaderFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save or nil
  end
end

function ShaderFrame:on_save()
  return self.image.value:newImageData():encode("png")
end

function ShaderFrame:refresh(image_data)
  if image_data then
    self.image_in = image_data
  else
    image_data = self.image_in
  end

  local cv = love.graphics.getCanvas()

  love.graphics.setCanvas(self.image.value)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  local shader_in = self.shader_in
  if shader_in then
    love.graphics.setShader(shader_in)
  end
  if image_data then
    local value = image_data.value
    local w, h = value:getDimensions()
    if self.size.x ~= w or self.size.y ~= h then
      self.image:replicate(image_data)
      self.size:setn(w, h)
    end
    love.graphics.draw(value)
  end
  love.graphics.setShader()
  love.graphics.setCanvas(cv)
  self.signal_out:inform(self.image)
end

function ShaderFrame:_ensure_valid_uniform(prop, value)
  local kind = self._uniform_kind_by_id[prop]
  return kind and kind.to_shader_value(value)
end

function ShaderFrame:_set_uniform(prop, value)
  local shader = self.shader_in
  if not (shader and shader:hasUniform(prop)) then return end
  value = self:_ensure_valid_uniform(prop, value)
  if not value then return end
  shader:send(prop, value)
end

function ShaderFrame:refresh_uniform(data, prop)
  self:_set_uniform(prop, data)
  self:refresh()
end

function ShaderFrame:refresh_uniforms()
  local uniform_ids   = self._uniform_ids
  local uniforms_in   = self._uniforms_in

  for index = 1, #uniform_ids do
    local prop = uniform_ids[index]
    local from = uniforms_in[prop]
    local success, result = try_invoke(from, "on_connect")
    self:_set_uniform(prop, success and result or nil)
  end
  self:refresh()
end

function ShaderFrame:refresh_shader(code)
  if not code then return end
  local success, data = pcall(love.graphics.newShader, code)
  self.shader_in = success and data or nil
  if success then
    self:detect_uniforms(code)
  end
  self:refresh_uniforms()
end

local known_uniform_kinds = {
  ["float"] = NumberKind;
  ["Image"] = ImageKind;
}

function ShaderFrame:detect_uniforms(code)
  local uniform_ids2   = self._uniform_ids2
  local uniform_kinds2 = self._uniform_kinds2
  local uniform_kind_by_id = self._uniform_kind_by_id

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
        uniform_kind_by_id[id] = kind
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
      app.disconnect_raw(self._view_, id)
      if not found_index then
        uniform_kind_by_id[id] = nil
      end
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
  local packet = self.signal_image
  if not packet then return end

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.value, 0, 0, 0, scale, scale)
end

function ShaderFrame:serialize()
  return "ShaderFrame {}"
end

return ShaderFrame
