local app                     = require "app"
local MenuListFrame           = require "frame.MenuList"
local LoadFileFrame           = require "frame.LoadFile"
local PixelFrame              = require "frame.Pixel"
local new_view_menu           = require "frame.menu.new_view"

local load_pixel_view = LoadFileFrame{
  on_load = function (_, data)
    app.add_view (1, {
      frame = PixelFrame {
        data = data;
      };
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
      text   = "Load Pixel View";
      action = function (_, _)
        app.show_popup(load_pixel_view)
      end;
    };
    { text = "Cancel"; }
  };
}