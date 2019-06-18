local Frame                   = require "Frame"
local IOs                     = require "IOs"
local ImagePacket             = require "packet.Image"
local Signal                  = require "Signal"
local ImageKind               = require "Kind.Image"
local NumberKind              = require "Kind.Number"
local Vector2Kind             = require "Kind.Vector2"
local VectorNKind             = require "Kind.VectorN"
local pleasure                = require "pleasure"
local clamp                   = require "math.clamp"

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local FULL_ROTATION = 2*math.pi

local ParticlesFrame = {}
ParticlesFrame.__index = ParticlesFrame
ParticlesFrame._kind = ";ParticlesFrame;Frame;"

local default_size_x = 128
local default_size_y = 128

local default_texture = love.image.newImageData(16, 8)
default_texture:mapPixel(function () return 1, 1, 1, 1 end)
default_texture = love.graphics.newImage(default_texture)

setmetatable(ParticlesFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "ParticlesFrame constructor must be a table.")
    frame.size_x = frame.size_x or default_size_x
    frame.size_y = frame.size_y or default_size_y

    ParticlesFrame.typecheck(frame, "ParticlesFrame constructor")

    frame.image = ImagePacket {
      value = love.graphics.newCanvas(frame.size_x, frame.size_y);
    }

    frame.signal_out = Signal {
      kind = ImageKind;
      on_connect = function ()
        return frame.image
      end;
    }

    local psystem = love.graphics.newParticleSystem(default_texture)
    psystem:setColors(1,0,0,1 ,  0.7,1,0,0.8 ,  0,0,0,0)
    psystem:setDirection( -math.pi/2 )
    psystem:setEmissionRate(60)
    -- psystem:setLinearDamping(min, max)
    psystem:setParticleLifetime(1, 3)
    --psystem:setLinearAcceleration( -100, -100, 100, 100 )
    psystem:setSizeVariation( 0.5 )
    psystem:setSizes( 0, 3 )
    psystem:setSpeed( 100 )
    psystem:setSpin( -math.pi, math.pi )
    psystem:setSpinVariation( 1 )
    psystem:setSpread( math.pi/3 )
    --psystem:setTangentialAcceleration( -10, 100 )
    psystem:setInsertMode( "bottom" )
    --psystem:setTexture(texture)
    psystem:setRotation( -math.pi, math.pi )
    --psystem:setRelativeRotation(true)
    --psystem:setRadialAcceleration(-1, 1)
    psystem:setPosition(frame.size_x/2, frame.size_y/2)
    --psystem:moveTo(x, y) -- similat to setPosition but smoother particle spawning behavior
    --psystem:setQuads(quad1, quad2, ...) -- Particles choose Quad based on current lifetime
    -- psystem:setEmissionArea( distribution, dx, dy, angle, directionRelativeToCenter )
      -- Newly created particles will spawn in an area around the emitter based on the parameters to this function.
    -- psystem:setOffset( x, y )
      -- Set the offset position which the particle sprite is rotated around. If this func
    psystem:start()
    frame.psystem = psystem


    setmetatable(frame, ParticlesFrame)

    return frame
  end;
})

ParticlesFrame.takes = {
  {id = "tick", kind = NumberKind};
  {id = "spread", kind = Vector2Kind};
  {id = "emissionRate", kind = NumberKind};
  {id = "speed", kind = Vector2Kind};
  {id = "sizes", kind = VectorNKind};
  {id = "sizeVariation", kind = NumberKind};
  {id = "position", kind = Vector2Kind};
}

ParticlesFrame.gives = IOs{
  {id = "signal_out", kind = ImageKind};
}

function ParticlesFrame:on_connect(prop, from, a, b, c, d, e, f, g, h)
  if prop == "tick" then
    self.signal_tick = from
    from:listen(self, prop, self.refresh_tick)
    self:refresh_tick(prop, a)
  elseif prop == "spread" then
    self.signal_spread = from
    from:listen(self, prop, self.refresh_spread)
    self:refresh_spread(prop, a, b)
  elseif prop == "sizes" then
    self.signal_sizes = from
    from:listen(self, prop, self.refresh_sizes)
    self:refresh_sizes(prop, a, b, c, d, e, f, g, h)
  elseif prop == "speed" then
    self.signal_speed = from
    from:listen(self, prop, self.refresh_speed)
    self:refresh_speed(prop, a, b)
  elseif prop == "sizeVariation" then
    self.signal_sizeVariation = from
    from:listen(self, prop, self.refresh_sizeVariation)
    self:refresh_sizeVariation(prop, a)
  elseif prop == "emissionRate" then
    self.signal_emissionRate = from
    from:listen(self, prop, self.refresh_emissionRate)
    self:refresh_emissionRate(prop, a)
  elseif prop == "position" then
    self.signal_position = from
    from:listen(self, prop, self.refresh_position)
    self:refresh_position(prop, a, b)
  end
end

function ParticlesFrame:on_disconnect(prop)
  if prop == "tick" then
    try_invoke(self.signal_tick, "unlisten", self, prop, self.refresh_tick)
    self.signal_tick = nil
    self:refresh_tick(prop, nil)
  elseif prop == "spread" then
    try_invoke(self.signal_spread, "unlisten", self, prop, self.refresh_spread)
    self.signal_spread = nil
    self:refresh_spread(prop, nil, nil)
  elseif prop == "sizes" then
    try_invoke(self.signal_sizes, "unlisten", self, prop, self.refresh_sizes)
    self.signal_sizes = nil
    self:refresh_sizes(prop, nil, nil, nil, nil, nil, nil, nil, nil)
  elseif prop == "speed" then
    try_invoke(self.signal_speed, "unlisten", self, prop, self.refresh_speed)
    self.signal_speed = nil
    self:refresh_speed(prop, nil, nil)
  elseif prop == "sizeVariation" then
    try_invoke(self.signal_sizeVariation, "unlisten", self, prop, self.refresh_sizeVariation)
    self.signal_sizeVariation = nil
    self:refresh_sizeVariation(prop, nil)
  elseif prop == "emissionRate" then
    try_invoke(self.signal_emissionRate, "unlisten", self, prop, self.refresh_emissionRate)
    self.signal_emissionRate = nil
    self:refresh_emissionRate(prop, nil)
  elseif prop == "position" then
    try_invoke(self.signal_position, "unlisten", self, prop, self.refresh_position)
    self.signal_position = nil
    self:refresh_position(prop, nil, nil)
  end
end

function ParticlesFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ParticlesFrame.is(obj)
  return is_metakind(obj, ";ParticlesFrame;")
end

function ParticlesFrame:check_action(action_id)
  if action_id == "core:save" then
    return self.on_save or nil
  end
end

function ParticlesFrame:on_save()
  return self.image.value:newImageData():encode("png")
end

function ParticlesFrame:refresh_tick()
  self.psystem:update(1/60)
  self:_redraw_image()
end

function ParticlesFrame:refresh_spread(_, min, delta)
  min = ((min or 0) - 0.25)*FULL_ROTATION
  delta = (delta or 0)*FULL_ROTATION
  self.psystem:setDirection(min + delta/2)
  self.psystem:setSpread(delta)
  self:_redraw_image()
end

function ParticlesFrame:refresh_sizes(_, v1, v2, v3, v4, v5, v6, v7, v8)
  if     v8 then self.psystem:setSizes(v1, v2, v3, v4, v5, v6, v7, v8)
  elseif v7 then self.psystem:setSizes(v1, v2, v3, v4, v5, v6, v7)
  elseif v6 then self.psystem:setSizes(v1, v2, v3, v4, v5, v6)
  elseif v5 then self.psystem:setSizes(v1, v2, v3, v4, v5)
  elseif v4 then self.psystem:setSizes(v1, v2, v3, v4)
  elseif v3 then self.psystem:setSizes(v1, v2, v3)
  elseif v2 then self.psystem:setSizes(v1, v2)
  elseif v1 then self.psystem:setSizes(v1)
  else           self.psystem:setSizes(1)
  end
  self:_redraw_image()
end

function ParticlesFrame:refresh_sizeVariation(_, variation)
  self.psystem:setSizeVariation(clamp(variation or 0), 0, 1)
  self:_redraw_image()
end

function ParticlesFrame:refresh_speed(_, min, max)
  min = min or 0
  self.psystem:setSpeed(min, max or min)
  self:_redraw_image()
end

function ParticlesFrame:refresh_emissionRate(_, rate)
  self.psystem:setEmissionRate(rate or 0)
  self:_redraw_image()
end

function ParticlesFrame:refresh_position(_, x, y)
  self.psystem:moveTo(x or self.size_x/2, y or self.size_y / 2)
  self:_redraw_image()
end

function ParticlesFrame:_redraw_image()
  local cv = love.graphics.getCanvas()
  love.graphics.setCanvas(self.image.value)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(self.psystem)
  love.graphics.setCanvas(cv)
  self.signal_out:inform(self.image)
end

function ParticlesFrame:draw(_, _, scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.value, 0, 0, 0, scale, scale)
end

function ParticlesFrame:serialize()
  return ([[ParticlesFrame {
    size_x = %s;
    size_y = %s;
  }]]):format(self.size_x, self.size_y)
end

return ParticlesFrame
