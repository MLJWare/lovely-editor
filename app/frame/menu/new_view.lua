local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local NewPixelViewFrame       = require "frame.NewPixelView"
local ColorPickerFrame        = require "frame.ColorPicker"
local ToolboxFrame            = require "frame.Toolbox"
local ShaderFrame             = require "frame.Shader"

return MenuListFrame {
  options = {
    {
      text   = "New Pixel View";
      action = function (_, _)
        app.show_popup(NewPixelViewFrame{
          create_pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Shader View";
      action = function (_, _)
        app.add_view(View{
          frame = ShaderFrame {};
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