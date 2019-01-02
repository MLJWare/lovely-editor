local topath                  = require "topath"

local atlas  = love.graphics.newImage(topath "res/atlas.png")
local atlas_w, atlas_h = atlas:getDimensions()
local lookup = require "res.atlas"

local function _info (id)
  local info = lookup[id]
  if not info then return nil end
  if not info.quad then
    info.quad = love.graphics.newQuad(info.x, info.y, info.w, info.h, atlas_w, atlas_h)
  end
  return info
end

local function _draw(id, x, y, sx, sy)
  local info = _info(id)
  if not info then return end -- NOTE ignores missing textures: Give warning/error instead!
  love.graphics.draw(atlas, info.quad, x, y, 0, sx or 1, sy or 1, info.ox or 0, info.oy or 0)
end

local function _ninepatch(id, x, y, w, h)
  local infoTL = _info(id.."-top-left")
  local infoMC = _info(id.."-middle-center")
  local infoBR = _info(id.."-bottom-right")

  local lw, mw, rw = infoTL.w, infoMC.w, infoBR.w
  local th, ch, bh = infoTL.h, infoMC.h, infoBR.h

  local sx, sy = (w-lw-rw)/mw, (h-th-bh)/ch

  local x2, y2, x3, y3 = x+lw, y+th, x+w-rw, y+h-bh
  local ox, oy = (infoMC.ox or 0)*sx, (infoMC.oy or 0)*sy -- TODO proper handling of offsets in ninepatches

  ---- fill
  _draw(id.."-middle-center", x2 - ox, y2 - oy, sx, sy)

  -- render top and bottom
  _draw(id.."-top-center"   , x2 - ox, y  - oy, sx, 1)
  _draw(id.."-bottom-center", x2 - ox, y3 - oy, sx, 1)

  -- render left and right
  _draw(id.."-middle-left" , x  - ox, y2 - oy, 1, sy)
  _draw(id.."-middle-right", x3 - ox, y2 - oy, 1, sy)

  -- render corners
  _draw(id.."-top-left"    , x  - ox, y  - oy, 1, 1)
  _draw(id.."-top-right"   , x3 - ox, y  - oy, 1, 1)
  _draw(id.."-bottom-left" , x  - ox, y3 - oy, 1, 1)
  _draw(id.."-bottom-right", x3 - ox, y3 - oy, 1, 1)
end

return {
  draw      = _draw;
  ninepatch = _ninepatch;
}
