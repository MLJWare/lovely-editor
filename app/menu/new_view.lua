local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local NewPixelViewFrame       = require "frame.NewPixelView"
local ColorPickerFrame        = require "frame.ColorPicker"
local ToolboxFrame            = require "frame.Toolbox"
local ViewGroupFrame          = require "frame.ViewGroup"
local ShaderFrame             = require "frame.Shader"
local NewParticlesViewFrame   = require "frame.NewParticlesView"
local LoveFrame               = require "frame.Love"
local TimelineFrame           = require "frame.Timeline"
local ConditionalFrame        = require "frame.Conditional"
local TextBufferFrame         = require "frame.TextBuffer"
local SettingsFrame           = require "frame.Settings"
local SliderFrame             = require "frame.Slider"
local new_math_view           = require "menu.new_math_view"

return MenuListFrame {
  options = {
    {
      text   = "New Settings View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view (View {
          frame = SettingsFrame {
            size_x = 128;
            size_y = 128;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Pixel View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.show_popup (NewPixelViewFrame {
          create_pos_x = popup_x;
          create_pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Text Buffer View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view (View {
          frame = TextBufferFrame {
            size_x = 128;
            size_y = 128;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Timeline View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view (View {
          frame = TimelineFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Slider View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view (View {
          frame = SliderFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Shader View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
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
        local popup_x, popup_y = app.popup_position()
        app.show_popup (NewParticlesViewFrame {
          create_pos_x = popup_x;
          create_pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Conditional View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view (View {
          frame = ConditionalFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Love View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view (View {
          frame = LoveFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "Math Views";
      action = function (_, _)
        app.show_popup( new_math_view, app.popup_position())
      end;
    };
    {
      text   = "New Group View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view(View {
          frame = ViewGroupFrame {
            size_x = 128;
            size_y = 128;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Color Picker View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view(View{
          frame = ColorPickerFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
          anchored = true;
        })
      end;
    };
    {
      text   = "New Toolbox View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position()
        app.add_view(View{
          frame = ToolboxFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
          anchored = true;
        })
      end;
    };
    { text = "Cancel"; }
  };
}
