local font_writer             = require "util.font_writer"
local Images                  = require "Images"
local assertf                 = require "assertf"
local vec2                    = require "linear-algebra.Vector2"

local Color                   = require "color.Color"
local font = love.graphics.newFont(12)


local Button = {}
Button.__index = Button

Button.text_color = Color{0, 0, 0}

setmetatable(Button, {
  __call = function (_, button)
    assert(type(button) == "table"        , "Button constructor must be a table.")
    assertf(vec2.is(button.size)          , "Missing/invalid property: 'size' must be a Vector2.")
    assertf(type(button.text) == "string" , "Missing/invalid property: 'text' must be a string.")
    setmetatable(button, Button)
    return button
  end;
})

function Button:draw ()
  if self.pressed then
    self:draw_pressed(self.size)
  elseif self.hovered then
    self:draw_hover(self.size)
  else
    self:draw_normal(self.size)
  end
end

function Button:draw_normal(size)
  love.graphics.setColor(0.9, 0.9, 0.9)
  Images.ninepatch("button", 0, 0, size.x, size.y - 1, 2)
  love.graphics.setColor(self.text_color)
  font_writer.print_aligned(font, self.text:upper(), size.x/2, size.y/2, "middle", "center")
end

function Button:draw_hover (size)
  love.graphics.setColor(1, 1, 1)
  Images.ninepatch("button", 0, 0, size.x, size.y - 1, 2)
  love.graphics.setColor(self.text_color)
  font_writer.print_aligned(font, self.text:upper(), size.x/2, size.y/2, "middle", "center")
end

function Button:draw_pressed (size)
  love.graphics.setColor(0.8, 0.8, 0.8)
  Images.ninepatch("button-pressed", 0, 0, size.x, size.y - 1, 2)
  love.graphics.setColor(self.text_color)
  font_writer.print_aligned(font, self.text:upper(), size.x/2, size.y/2, "middle", "center")
end

return Button
