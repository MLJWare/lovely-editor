local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
--local ViewGroupFrame          = require "frame.ViewGroup"
local LoveFrame               = require "frame.Love"
local TextBufferFrame         = require "frame.TextBuffer"
--local SettingsFrame           = require "frame.Settings"
local new_math_view           = require "menu.new_math_view"
local new_control_view        = require "menu.new_control_view"
local new_graphics_view       = require "menu.new_graphics_view"

return MenuListFrame {
  options = {
    --[[{
      text   = "New Settings View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = SettingsFrame {
            size_x = 128;
            size_y = 128;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };--]]
    {
      text   = "New Text Buffer View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
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
      text   = "New Love View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
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
      text   = "Graphics Views";
      action = function (_, _)
        app.show_popup( new_graphics_view, app.popup_position())
      end;
    };
    {
      text   = "Control Views";
      action = function (_, _)
        app.show_popup( new_control_view, app.popup_position())
      end;
    };
    --[[{
      text   = "New Group View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View {
          frame = ViewGroupFrame {
            size_x = 128;
            size_y = 128;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };--]]
    { text = "Cancel"; }
  };
}
