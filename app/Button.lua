local font_writer             = require "util.font_writer"
local Images                  = require "Images"
local assertf                 = require "assertf"
local unpack_color            = require "util.color.unpack"
local is_non_negative         = require ("pleasure.is").non_negative_number
local fontstore               = require "fontstore"
local font = fontstore.default[12]

local Button = {}
Button.__index = Button

Button.text_color = 0x000000FF



setmetatable(Button, {
  __call = function (_, button)
    assert(type(button) == "table", "Button constructor must be a table.")
    assertf(is_non_negative(button.size_x), "Missing/invalid property: 'size_x' must be a non-negative number.")
    assertf(is_non_negative(button.size_y), "Missing/invalid property: 'size_y' must be a non-negative number.")
    assertf(type(button.text) == "string" , "Missing/invalid property: 'text' must be a string.")
    setmetatable(button, Button)
    return button
  end;
})

function Button:draw ()
  if self.pressed then
    self:_draw_pressed(self.size_x, self.size_y)
  elseif self.hovered then
    self:_draw_hover(self.size_x, self.size_y)
  else
    self:_draw_normal(self.size_x, self.size_y)
  end
end

function Button:_draw_normal(size_x, size_y)
  love.graphics.setColor(0.9, 0.9, 0.9)
  Images.ninepatch("button", 0, 0, size_x, size_y - 1, 2)
  love.graphics.setColor(unpack_color(self.text_color))
  font_writer.print_aligned(font, self.text:upper(), size_x/2, size_y/2, "middle", "center")
end

function Button:_draw_hover (size_x, size_y)
  love.graphics.setColor(1, 1, 1)
  Images.ninepatch("button", 0, 0, size_x, size_y - 1, 2)
  love.graphics.setColor(unpack_color(self.text_color))
  font_writer.print_aligned(font, self.text:upper(), size_x/2, size_y/2, "middle", "center")
end

function Button:_draw_pressed (size_x, size_y)
  love.graphics.setColor(0.8, 0.8, 0.8)
  Images.ninepatch("button-pressed", 0, 0, size_x, size_y - 1, 2)
  love.graphics.setColor(unpack_color(self.text_color))
  font_writer.print_aligned(font, self.text:upper(), size_x/2, size_y/2, "middle", "center")
end

return Button
