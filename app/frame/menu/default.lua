local app                     = require "app"
local MenuListFrame           = require "frame.MenuList"
local LoadFileFrame           = require "frame.LoadFile"
local new_view_menu           = require "frame.menu.new_view"

local load_as_view = LoadFileFrame{
  on_load = function (_, format, data, filename)
    local frame = app.try_create_frame(format, data)
    if frame then
      frame.filename = filename
      app.add_view (1, {
        frame = frame;
        pos   = app.popup_position();
        scale = 1;
      })
    end
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