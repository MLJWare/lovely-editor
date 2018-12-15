local font_writer = {}

local alignment = {
  ["top"   ] =  0;
  ["left"  ] =  0;
  ["middle"] = -0.5;
  ["center"] = -0.5;
  ["bottom"] = -1;
  ["right" ] = -1;
}

local function round(x) return math.floor(x + 0.5) end

function font_writer.print_aligned(font, text, x, y, align_x, align_y)
  local line_count = (select(2, text:gsub('\n', '\n')) or 0) + 1
  local width  = font:getWidth(text)
  local height = font:getHeight()*line_count

  local dx = type(align_x) == "string" and alignment[align_x or "left"] or align_x or 0
  local dy = type(align_y) == "string" and alignment[align_y or "top" ] or align_y or 0

  love.graphics.setFont(font)
  love.graphics.print(text, round(x + dx*width), round(y + dy*height))
end

function font_writer.print(font, text, x, y, r, ox, oy, kx, ky)
  love.graphics.setFont(font)
  love.graphics.print(text, round(x), round(y), r, 1, 1, ox, oy, kx, ky)
end

return font_writer
