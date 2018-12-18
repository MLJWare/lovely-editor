local app                     = require "app"
local vec2                    = require "linear-algebra.Vector2"
local MenuListFrame           = require "frame.MenuList"
local LoadFileFrame           = require "frame.LoadFile"
local PixelFrame              = require "frame.Pixel"
local TextFrame               = require "frame.Text"
local new_view_menu           = require "frame.menu.new_view"

local load_as_view = LoadFileFrame{
  on_load = function (_, format, data)
    local frame
    if format == "image" then
      frame = PixelFrame {
        data = data;
      };
    else
      frame = TextFrame{
        text = data;
        size = vec2(256, 256);
      };
    end
    app.add_view (1, {
      frame = frame;
      pos   = app.popup_position();
      scale = 1;
    })
  end;
}

return MenuListFrame {
  options = {
    {
      text   = "New View";
      action = function (_, _)
        app.show_popup(new_view_menu, app.popup_position())
      end;
    };
    {
      text   = "Load As View";
      action = function (_, _)
        app.show_popup(load_as_view)
      end;
    };
    { text = "Cancel"; }
  };
}