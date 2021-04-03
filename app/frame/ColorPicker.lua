local Frame                   = require "Frame"
local clamp                   = require "math.clamp"
local hue_shader              = require "shader.gradient.hue"
local gradient_shader         = require "shader.gradient.sat_val"
local alpha_shader            = require "shader.gradient.alpha"
local shader_fill             = require "shader_fill"
local hsv2rgb                 = require "color.hsv2rgb"
local Signal                  = require "Signal"
local Vector4Kind             = require "Kind.Vector4"
local IOs                     = require "IOs"
local is                      = require "pleasure.is"

local is_table = is.table
local is_metakind = is.metakind

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

local ColorPickerFrame = {}
ColorPickerFrame.__index = ColorPickerFrame
ColorPickerFrame._kind = ";ColorPickerFrame;Frame;"

setmetatable(ColorPickerFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "ColorPickerFrame constructor must be a table.")
    frame.size_x = FULL_WIDTH
    frame.size_y = FULL_HEIGHT
    ColorPickerFrame.typecheck(frame, "ColorPickerFrame constructor")
    setmetatable(frame, ColorPickerFrame)

    local hue = frame._hue or 0
    local sat = frame._sat or 0
    local val = frame._val or 0
    frame._hue = hue
    frame._sat = sat
    frame._val = val
    frame._red
    , frame._green
    , frame._blue = hsv2rgb(hue, sat, val)
    frame._alpha = frame._alpha or 1

    frame.color_signal = Signal {
      kind = Vector4Kind;
      on_connect = function ()
        return frame._red, frame._green, frame._blue, frame._alpha
      end;
    }
    return frame
  end;
})

ColorPickerFrame.gives = IOs{
  {id = "color_signal"; kind = Vector4Kind ;}
}

function ColorPickerFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function ColorPickerFrame.is(obj)
  return is_metakind(obj, ";ColorPickerFrame;")
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


function ColorPickerFrame:set_color_hue(hue)
  self._hue = clamp(hue, 0, 6)
  self:_on_change()
end

function ColorPickerFrame:set_color_sat_val(sat, val)
  self._sat = clamp(sat, 0, 1)
  self._val = clamp(val, 0, 1)
  self:_on_change()
end

function ColorPickerFrame:set_color_alpha(alpha)
  self._alpha = clamp(alpha, 0, 1)
  self:_on_change()
end

function ColorPickerFrame:_on_change()
  local hue = self._hue
  local sat = self._sat
  local val = self._val
  local red, green, blue = hsv2rgb(hue, sat, val)
  local alpha = self._alpha
  self._red = red
  self._green = green
  self._blue = blue
  self.color_signal:inform(red, green, blue, alpha)
end

function ColorPickerFrame:draw(size_x, size_y, _)
  local width, height = size_x, size_y

  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle("fill", 0, 0, width, height)

  love.graphics.push()
  love.graphics.scale(size_x / FULL_WIDTH, size_y / FULL_HEIGHT)
  local hue = self._hue
  local sat = self._sat
  local val = self._val
  local alpha = self._alpha
  local r, g, b = hsv2rgb(hue, sat, val)

  gradient_shader:send("hue", hue)
  alpha_shader:send("hue", hue)
  alpha_shader:send("sat", sat)
  alpha_shader:send("val", val)

  love.graphics.setColor(r, g, b)
  love.graphics.rectangle("fill", INDICATOR_X, INDICATOR_Y, INDICATOR_WIDTH, INDICATOR_HEIGHT)

  draw_slider(HUE_X, HUE_Y, SLIDER_WIDTH, SLIDER_HEIGHT, hue_shader, hue/6)
  draw_slider(ALPHA_X, ALPHA_Y, SLIDER_WIDTH, SLIDER_HEIGHT, alpha_shader, alpha)
  draw_field(FIELD_X, FIELD_Y, FIELD_WIDTH, FIELD_HEIGHT, gradient_shader, sat, val)

  love.graphics.pop()
end

function ColorPickerFrame:mousepressed(mx, my, button)
  if button ~= 1 then return end
  if contains(HUE_X, HUE_Y, SLIDER_WIDTH, SLIDER_HEIGHT, mx, my) then
    local hue = 6*(1 - (my - HUE_Y)/SLIDER_HEIGHT)
    self:set_color_hue(hue)
    self.picked = "hue"
  elseif contains(FIELD_X, FIELD_Y, FIELD_WIDTH, FIELD_HEIGHT, mx, my) then
    local sat =     (mx - FIELD_X)/FIELD_WIDTH
    local val = 1 - (my - FIELD_Y)/FIELD_HEIGHT
    self:set_color_sat_val(sat, val)
    self.picked = "sat-val"
  elseif contains(ALPHA_X, ALPHA_Y, SLIDER_WIDTH, SLIDER_HEIGHT, mx, my) then
    local alpha = 1 - (my - ALPHA_Y)/SLIDER_HEIGHT
    self:set_color_alpha(alpha)
    self.picked = "alpha"
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
    local hue = 6*(1 - (my - HUE_Y)/SLIDER_HEIGHT)
    self:set_color_hue(hue)
  elseif picked == "sat-val" then
    local sat =     (mx - FIELD_X)/FIELD_WIDTH
    local val = 1 - (my - FIELD_Y)/FIELD_HEIGHT
    self:set_color_sat_val(sat, val)
  elseif picked == "alpha" then
    local alpha = 1 - (my - ALPHA_Y)/SLIDER_HEIGHT
    self:set_color_alpha(alpha)
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

function ColorPickerFrame:serialize()
  return ([[ColorPickerFrame {
    _hue = %s;
    _sat = %s;
    _val = %s;
    _alpha = %s;
  }]]):format(self._hue, self._sat, self._val, self._alpha)
end

return ColorPickerFrame
