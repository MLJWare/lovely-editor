local app                     = require "app"
local MenuListFrame           = require "frame.MenuList"
local LoadFileFrame           = require "frame.LoadFile"
local SaveFileFrame           = require "frame.SaveFile"
local YesNoCancelFrame        = require "frame.YesNoCancel"
local new_view_menu           = require "menu.new_view"
local load_data               = require "util.file.load_data"
local try_create_project      = require "internal.try_create_project"

local load_as_view = LoadFileFrame{
  on_load = function (_, filename, filedata)
    local data, format = load_data(filename, filedata)
    if not data then
      error(("Couldn't load file %q; perhaps it isn't an image/text file?"):format(filename))
    end

    local frame = app.try_create_frame(format, data)
    if frame then
      frame.filename = filename
      local popup_x, popup_y = app.popup_position_as_local()
      app.add_view (1, {
        frame = frame;
        pos_x = popup_x;
        pos_y = popup_y;
        scale = 1;
      })
    end
  end;
}

local load_project = require "dialog.load_project"
local save_project = require "dialog.save_project"
local save_project_before_load = require "dialog.save_project_before_load"

local ask_save_before_load = YesNoCancelFrame {
  title = "Save current project?";
  text  = "Do you want to save the current project before loading?";
  option_yes = function ()
    app.show_popup(save_project_before_load)
  end;
  option_no  = function ()
    app.show_popup(load_project)
  end;
}

local save_project_before_new = SaveFileFrame{
  action = save_project.action;
  on_saved = function ()
    app.restart()
  end;
}

local ask_save_before_new = YesNoCancelFrame {
  title = "Save current project?";
  text  = "Do you want to save the current project before starting a new?";
  option_yes = function ()
    app.show_popup(save_project_before_new)
  end;
  option_no  = function ()
    app.restart()
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
    {
      text   = "Save Project";
      action = function (_, _)
        app.show_popup(save_project)
      end;
    };
    {
      text   = "New Project";
      action = function (_, _)
        if #app.project.views > 0 then
          app.show_popup(ask_save_before_new)
        end
      end;
    };
    {
      text   = "Load Project";
      action = function (_, _)
        if #app.project.views > 0 then
          app.show_popup(ask_save_before_load)
        else
          app.show_popup(load_project)
        end
      end;
    };
    { text = "Cancel"; }
  };
}
