local app                     = require "app"
local vec2                    = require "linear-algebra.Vector2"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local IntegerFrame            = require "frame.Integer"
local SumFrame                = require "frame.Sum"
local TimerFrame              = require "frame.Timer"
local NewPixelViewFrame       = require "frame.NewPixelView"
local ColorPickerFrame        = require "frame.ColorPicker"
local ToolboxFrame            = require "frame.Toolbox"
local ViewGroupFrame          = require "frame.ViewGroup"
local ShaderFrame             = require "frame.Shader"

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
      text   = "New Shader View";
      action = function (_, _)
        app.add_view (View {
          frame = ShaderFrame {};
          pos = app.popup_position ();
        })
      end;
    };
    {
      text   = "New Integer View";
      action = function (_, _)
        app.add_view(View{
          frame = IntegerFrame {};
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Sum View";
      action = function (_, _)
        app.add_view(View{
          frame = SumFrame {};
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Timer View";
      action = function (_, _)
        app.add_view(View{
          frame = TimerFrame {};
          pos = app.popup_position();
        })
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