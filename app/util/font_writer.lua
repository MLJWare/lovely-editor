local is                      = require "pleasure.is"

local is_string = is.string

local font_writer = {}

local alignment = {
  ["top"   ] = 0.0;
  ["left"  ] = 0.0;
  ["middle"] = 0.5;
  ["center"] = 0.5;
  ["bottom"] = 1.0;
  ["right" ] = 1.0;
}

local function round(x) return math.floor(x + 0.5) end

function font_writer.print_aligned(font, text, x, y, align_x, align_y)
  text = tostring(text)
  local line_count = (select(2, text:gsub('\n', '\n')) or 0) + 1
  local width  = font:getWidth(text)
  local height = font:getHeight()*line_count

  local dx = is_string(align_x) and alignment[align_x or "left"] or align_x or 0
  local dy = is_string(align_y) and alignment[align_y or "top" ] or align_y or 0

  local old_font = love.graphics.getFont()
  love.graphics.setFont(font)
  love.graphics.print(text, round(x - dx*width), round(y - dy*height))
  love.graphics.setFont(old_font)
end

function font_writer.print(font, text, x, y, r, ox, oy, kx, ky)
  text = tostring(text)
  local old_font = love.graphics.getFont()
  love.graphics.setFont(font)
  love.graphics.print(text, round(x), round(y), r, 1, 1, ox, oy, kx, ky)
  love.graphics.setFont(old_font)
end

return font_writer
