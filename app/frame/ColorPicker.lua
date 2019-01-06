local Frame                   = require "Frame"
local PropertyStore           = require "PropertyStore"
local clamp                   = require "math.clamp"
local hue_shader              = require "shader.gradient.hue"
local gradient_shader         = require "shader.gradient.sat_val"
local alpha_shader            = require "shader.gradient.alpha"
local shader_fill             = require "shader_fill"
local rgb2hsv                 = require "color.rgb2hsv"
local hsv2rgb                 = require "color.hsv2rgb"
local Color                   = require "color.Color"
local vec2                    = require "linear-algebra.Vector2"
local MouseButton             = require "const.MouseButton"
local PAD = 4

local SLIDER_WIDTH  = 16
local SLIDER_HEIGHT = 256

local FIELD_WIDTH   = 256
local FIELD_HEIGHT  = SLIDER_HEIGHT

local INDICATOR_HEIGHT = 32

local INDICATOR_X = PAD
local INDICATOR_Y = PAD

local HUE_X = INDICATOR_X
local HUE_Y = INDICATOR_Y + INDICATOR_HEIGHT + PAD

local FIELD_X = HUE_X + SLIDER_WIDTH + PAD
local FIELD_Y = HUE_Y

local ALPHA_X = FIELD_X + FIELD_WIDTH + PAD
local ALPHA_Y = HUE_Y

local INDICATOR_WIDTH  = ALPHA_X + SLIDER_WIDTH - PAD

local FULL_WIDTH  = INDICATOR_WIDTH  + 2*PAD
local FULL_HEIGHT = INDICATOR_HEIGHT + 3*PAD + FIELD_HEIGHT

local function contains(x, y, w, h, mx, my)
  return x <= mx and mx < x + w
     and y <= my and my < y + h
end

local function get_rgba()
  return unpack(PropertyStore.get("core.graphics", "paint.color"))
end

local function set_color_hue(h)
  local r, g, b, a = get_rgba()
  local _, s, v = rgb2hsv(r, g, b)
  r, g, b = hsv2rgb(h, s, v)
  return PropertyStore.set("core.graphics", "paint.color", Color{r, g, b, a})
end

local function set_color_sat_val(s, v)
  local r, g, b, a = get_rgba()
  local h, _, _ = rgb2hsv(r, g, b)
  r, g, b = hsv2rgb(h, s, v)
  return PropertyStore.set("core.graphics", "paint.color", Color{r, g, b, a})
end

local function set_color_alpha(a)
  local r, g, b, _ = get_rgba()
  return PropertyStore.set("core.graphics", "paint.color", Color{r, g, b, a})
end


local ColorPickerFrame = {}
ColorPickerFrame.__index = ColorPickerFrame

ColorPickerFrame._kind = ";ColorPickerFrame;Frame;"

setmetatable(ColorPickerFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(type(frame) == "table", "ColorPickerFrame constructor must be a table.")
    frame.size = vec2(FULL_WIDTH, FULL_HEIGHT)
    ColorPickerFrame.typecheck(frame, "ColorPickerFrame constructor")
    setmetatable(frame, ColorPickerFrame)

    local r, g, b, a = get_rgba()
    frame:_set_text_from_rgba(r, g, b, a)
    return frame
  end;
})

function ColorPickerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ColorPickerFrame.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
     and type(meta._kind) == "string"
     and meta._kind:find(";ColorPickerFrame;")
end

local function draw_slider_knob(x, y, width, height)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle( "fill", x, y, width, height)
  love.graphics.setColor(.6,.6,.6)
  love.graphics.rectangle( "line", x +.5, y+.5, width-1, height-1)
end

local function draw_slider(x, y, width, height, shader, pct)
  x, y = math.floor(x), math.floor(y)
  local knob_y = math.floor(y + (1-pct)*height)
  shader_fill(shader, x, y, width, height)
  draw_slider_knob(x, knob_y - 4, width, 8)
end

local function draw_field_knob(x, y)
  love.graphics.setLineWidth(4)
  love.graphics.setColor(0.5, 0.5, 0.5)
  love.graphics.circle("line", x, y, 5)
  love.graphics.setLineWidth(2)
  love.graphics.setColor(1, 1, 1)
  love.graphics.circle("line", x, y, 5)
  love.graphics.setLineWidth(1)
end

local function draw_field(x, y, width, height, shader, pct_x, pct_y)
  x, y  = math.floor(x), math.floor(y)
  local knob_x = math.floor(x + pct_x*width)
  local knob_y = math.floor(y + (1-pct_y)*height)
  shader_fill(shader, x, y, width, height)
  draw_field_knob(knob_x, knob_y)
end

function ColorPickerFrame:_set_text_from_rgba(r, g, b, a)
  self.text = ("rgba(%d, %d, %d, %d)"):format(r*255, g*255, b*255, a*255)
end

function ColorPickerFrame.draw(_, size, _)
  local width, height = size.x, size.y

  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.push()
  love.graphics.scale(size.x / FULL_WIDTH, size.y / FULL_HEIGHT)
  local r, g, b, alpha = get_rgba()
  local hue, sat, val = rgb2hsv(r, g, b)

  gradient_shader:send("hue", hue)
  alpha_shader:send("hue", hue)
  alpha_shader:send("sat", sat)
  alpha_shader:send("val", val)

  draw_slider(HUE_X, HUE_Y, SLIDER_WIDTH, SLIDER_HEIGHT, hue_shader, hue/6)
  draw_slider(ALPHA_X, ALPHA_Y, SLIDER_WIDTH, SLIDER_HEIGHT, alpha_shader, alpha)
  draw_field(FIELD_X, FIELD_Y, FIELD_WIDTH, FIELD_HEIGHT, gradient_shader, sat, val)

  love.graphics.setColor(r, g, b)
  love.graphics.rectangle("fill", INDICATOR_X, INDICATOR_Y, INDICATOR_WIDTH, INDICATOR_HEIGHT)
  love.graphics.pop()
end

function ColorPickerFrame:_on_change()
  local r, g, b, a = get_rgba()
  self:_set_text_from_rgba(r, g, b, a)
  --try_invoke(self, "on_change", r, g, b, a)
end

function ColorPickerFrame:mousepressed(mx, my, button)
  if button ~= MouseButton.LEFT then return end
  if contains(HUE_X, HUE_Y, SLIDER_WIDTH, SLIDER_HEIGHT, mx, my) then
    local hue = 6*clamp(1 - (my - HUE_Y)/SLIDER_HEIGHT, 0, 1)
    set_color_hue(hue)
    self.picked = "hue"
    self:_on_change()
  elseif contains(FIELD_X, FIELD_Y, FIELD_WIDTH, FIELD_HEIGHT, mx, my) then
    local sat = clamp(    (mx - FIELD_X)/FIELD_WIDTH , 0, 1)
    local val = clamp(1 - (my - FIELD_Y)/FIELD_HEIGHT, 0, 1)
    set_color_sat_val(sat, val)
    self.picked = "sat-val"
    self:_on_change()
  elseif contains(ALPHA_X, ALPHA_Y, SLIDER_WIDTH, SLIDER_HEIGHT, mx, my) then
    local alpha = clamp(1 - (my - ALPHA_Y)/SLIDER_HEIGHT, 0, 1)
    set_color_alpha(alpha)
    self.picked = "alpha"
    self:_on_change()
  --elseif contains(INDICATOR_X, INDICATOR_Y, INDICATOR_WIDTH, INDICATOR_HEIGHT, mx, my) then
    --self.picked = "text"
    ---- active text
  else
    self.picked = nil
  end
end

function ColorPickerFrame:mousereleased(_, _, button)
  if button ~= 1 then return end
  self.picked = nil
end

function ColorPickerFrame:mousedragged1(mx, my, _, _)
  local picked = self.picked
  if picked == "hue" then
    local hue = 6*clamp(1 - (my - HUE_Y)/SLIDER_HEIGHT, 0, 1)
    set_color_hue(hue)
    self:_on_change()
  elseif picked == "sat-val" then
    local sat = clamp(    (mx - FIELD_X)/FIELD_WIDTH , 0, 1)
    local val = clamp(1 - (my - FIELD_Y)/FIELD_HEIGHT, 0, 1)
    set_color_sat_val(sat, val)
    self:_on_change()
  elseif picked == "alpha" then
    local alpha = clamp(1 - (my - ALPHA_Y)/SLIDER_HEIGHT, 0, 1)
    set_color_alpha(alpha)
    self:_on_change()
  --elseif picked == "text" and self.active then
    ---- highlight text
  end
end

--[[
function ColorPicker:textinput(input)
  if self.picked ~= "text" or not self.active then return end
  -- self._edit:textinput(input)
end

function ColorPicker:keypressed (key, scancode, isrepeat)
  if self.picked ~= "text" or not self.active then return end
  self._edit:keypressed (key, scancode, isrepeat)
end
--]]

return ColorPickerFrame
