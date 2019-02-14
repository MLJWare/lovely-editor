local Frame                   = require "Frame"
local IOs                     = require "IOs"
local ImagePacket             = require "packet.Image"
local Signal                  = require "Signal"
local ImageKind               = require "Kind.Image"
local NumberKind              = require "Kind.Number"
local try_invoke              = require "pleasure.try".invoke

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
    assert(type(frame) == "table", "ParticlesFrame constructor must be a table.")
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
    --psystem:setPosition(x, y)
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
  {id = "tick", kind = NumberKind}
}

ParticlesFrame.gives = IOs{
  {id = "signal_out", kind = ImageKind};
}

function ParticlesFrame:on_connect(prop, from, data)
  if prop == "tick" then
    self.signal_tick = from
    from:listen(self, prop, self.refresh_tick)
    self:refresh_tick(prop, data)
  end
end

function ParticlesFrame:on_disconnect(prop)
  if prop == "tick" then
    try_invoke(self.signal_tick, "unlisten", self, prop, self.refresh_tick)
    self.signal_tick = nil
    self:refresh_tick(prop, nil)
  end
end

function ParticlesFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ParticlesFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ParticlesFrame;")
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
  local cv = love.graphics.getCanvas()
  love.graphics.setCanvas(self.image.value)
  love.graphics.clear   (0,0,0,0)
  love.graphics.setColor(1,1,1,1)

  self.psystem:update(1/60)
  local size_x = self.size_x
  local size_y = self.size_y
  self.psystem:setPosition(size_x/2, size_y/2)
  love.graphics.draw(self.psystem)

  -- TODO update and render particles
  love.graphics.setCanvas(cv)
  self.signal_out:inform(self.image)
end

function ParticlesFrame:draw(_, _, scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(self.image.value, 0, 0, 0, scale, scale)
end

function ParticlesFrame.serialize()
  return "ParticlesFrame {}"
end

return ParticlesFrame
