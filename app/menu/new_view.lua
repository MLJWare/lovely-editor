local app                     = require "app"
local vec2                    = require "linear-algebra.Vector2"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local NewPixelViewFrame       = require "frame.NewPixelView"
local ColorPickerFrame        = require "frame.ColorPicker"
local ToolboxFrame            = require "frame.Toolbox"
local ViewGroupFrame          = require "frame.ViewGroup"
local ShaderFrame             = require "frame.Shader"
local LoveFrame               = require "frame.Love"
local TextBufferFrame         = require "frame.TextBuffer"
local new_math_view           = require "menu.new_math_view"

return MenuListFrame {
  options = {
    {
      text   = "New Pixel View";
      action = function (_, _)
        app.show_popup (NewPixelViewFrame {
          create_pos = app.popup_position ();
        })
      end;
    };
    {
      text   = "New Text Buffer View";
      action = function (_, _)
        app.add_view (View {
          frame = TextBufferFrame {
            size = vec2(128, 128);
          };
          pos = app.popup_position ();
        })
      end;
    };
    {
      text   = "New Shader View";
      action = function (_, _)
        app.add_view (View {
          frame = ShaderFrame {};
          pos = app.popup_position ();
        })
      end;
    };
    {
      text   = "New Love View";
      action = function (_, _)
        app.add_view (View {
          frame = LoveFrame {};
          pos = app.popup_position ();
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
        app.add_view(View {
          frame = ViewGroupFrame {
            size = vec2(128, 128);
          };
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Color Picker View";
      action = function (_, _)
        app.add_view(View{
          frame = ColorPickerFrame {};
          pos = app.popup_position();
          anchored = true;
        })
      end;
    };
    {
      text   = "New Toolbox View";
      action = function (_, _)
        app.add_view(View{
          frame = ToolboxFrame {};
          pos = app.popup_position();
          anchored = true;
        })
      end;
    };
    { text = "Cancel"; }
  };
}
