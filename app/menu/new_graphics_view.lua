local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local new_sized_view_action = require "frame.menu-actions.new_sized_view"
local PixelFrame            = require "frame.Pixel"
local ColorPickerFrame        = require "frame.ColorPicker"
local ToolboxFrame            = require "frame.Toolbox"
local ShaderFrame             = require "frame.Shader"
local NewParticlesViewFrame   = require "frame.NewParticlesView"

local function create_new_pixel_frame(_, width, height)
  return PixelFrame {
    data = love.image.newImageData(width, height);
  };
end

return MenuListFrame {
  options = {
    {
      text = "New Pixel View";
      action = new_sized_view_action;
      create_new_frame = create_new_pixel_frame;
    };
    --[[{
      text   = "New Timeline View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = TimelineFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };--]]
    {
      text   = "New Shader View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = ShaderFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Particles View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.show_popup (NewParticlesViewFrame {
          create_pos_x = popup_x;
          create_pos_y = popup_y;
        })
      end;
    };
    --[[{
      text   = "New Particles Settings View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = ParticleSettingsFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };--]]
    {
      text   = "New Color Picker View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = ColorPickerFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Toolbox View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = ToolboxFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    { text = "Cancel"; }
  };
}
