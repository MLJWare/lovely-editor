local Frame                   = require "Frame"
local Images                  = require "Images"
local find_max                = require "fn.find_max"
local try_invoke              = require ("pleasure.try").invoke
local fontstore               = require "fontstore"

local MenuListFrame = {}
MenuListFrame.__index = MenuListFrame

MenuListFrame._kind = ";MenuListFrame;Frame;"

-- TODO remove this!!!
MenuListFrame.x = -1
MenuListFrame.y = -1

local menu_pad = 4
local font = fontstore.default[12]

local function _option_text(i, option)
  if i == 10 then
    i = "0"
  elseif i > 9 then
    i = ".."
  end
  return ("%s) %s"):format(i, option.text or "<...>")
end

local function option_text_width(option, i)
  return love.graphics.getFont():getWidth(_option_text(i, option))
end

setmetatable(MenuListFrame, {
  __index = Frame;
  __call = function (_, menu)
    assert(type(menu) == "table", "MenuListFrame constructor must be a table.")
    menu.size_x = menu.size_x or 0
    menu.size_y = menu.size_y or 0
    MenuListFrame.typecheck(menu, "MenuListFrame constructor")

    local options = menu.options
    local row_width  = find_max(option_text_width, options, 0)
    local row_height = font:getHeight()

    local width  = row_width + 2*menu_pad
    local height = #options*(row_height + menu_pad) + menu_pad

    menu.size_x = width
    menu.size_y = height
    menu.row_size_x = row_width
    menu.row_size_y = row_height

    setmetatable(Frame(menu), MenuListFrame)
    return menu
  end;
})

function MenuListFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function MenuListFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";MenuListFrame;")
end

function MenuListFrame:option_at(mx, my)
  local row_size_x = self.row_size_x
  local row_size_y = self.row_size_y
  local x2 = menu_pad
  if not (x2 <= mx and mx < x2 + row_size_x) then return nil end

  local row_offset = row_size_y + menu_pad
  local index = 1 + math.floor((my - menu_pad)/row_offset)

  return self.options[index]
end

function MenuListFrame:globalmousepressed()
  self:close()
end

function MenuListFrame:_is_disabled(option)
  return option.condition and not option:condition(self)
end

function MenuListFrame:mousepressed(mx, my, button)
  if button ~= 1 then return end
  local option = self:option_at(mx, my)
  if not option or self:_is_disabled(option) then return end
  try_invoke(option, "action", self)
  self:close()
end

function MenuListFrame:keypressed(key)
  if key == "escape" then
    return self:close()
  end

  local index = tonumber(key)
  if not index then return end
  index = (index - 1)%10 + 1
  local option = self.options[index]
  if option then
    try_invoke(option, "action", self)
    self:close()
  end
end

function MenuListFrame:draw(_, _, _, mx, my)
  local size_x = self.size_x
  local size_y = self.size_y
  local row_size_x = self.row_size_x
  local row_size_y = self.row_size_y

  local row_offset = row_size_y + menu_pad

  love.graphics.setColor(1,1,1)
  Images.ninepatch("menu", 0, 0, size_x, size_y)

  local options = self.options
  for i = 1, #options do
    local x2 = menu_pad
    local y2 = menu_pad + (i - 1)*row_offset

    local option = options[i]
    local disabled = self:_is_disabled(option)
    local contains = x2 <= mx and mx < x2 + row_size_x
                 and y2 <= my and my < y2 + row_offset

    if contains then
      love.graphics.setColor(0.2, 0.2, 0.2)
      love.graphics.rectangle("fill", x2, y2, row_size_x, row_size_y)
    end

    if disabled then
      love.graphics.setColor(0.6, 0.6, 0.6)
    elseif contains then
      love.graphics.setColor(1.0, 1.0, 1.0)
    else
      love.graphics.setColor(0.0, 0.0, 0.0)
    end
    love.graphics.print(_option_text(i, option), x2, y2)
  end
end

return MenuListFrame
