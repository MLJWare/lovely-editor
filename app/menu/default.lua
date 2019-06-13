local app                     = require "app"
local MenuListFrame           = require "frame.MenuList"
local LoadFileFrame           = require "frame.LoadFile"
local SaveFileFrame           = require "frame.SaveFile"
local YesNoCancelFrame        = require "frame.YesNoCancel"
local new_view_menu           = require "menu.new_view"
local load_data               = require "util.file.load_data"
local try_create_project      = require "internal.try_create_project"

local load_as_view = LoadFileFrame{
  on_load = function (_, file, filename)
    local data, format = load_data(file)
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

local load_project = LoadFileFrame {
  on_load = function (_, file, filename)
    local data
    if file:open("r") then
      data = file:read()
      file:close()
    end

    if data then
      local project, msg = try_create_project(data, filename)

      if project then
        app._set_project(project)
        return
      else
        print(msg)
      end
    end
    print(("Invalid project file: %s"):format(filename))
  end;
}

local save_project = SaveFileFrame{
  action = function (_, filename)
    local data = app.project:serialize()
    if filename:find("%.lp_raw$") then
      return data
    end
    return love.data.compress("data", "lz4", data)
  end;
}

local save_project_before_load = SaveFileFrame{
  action = save_project.action;
  on_saved = function ()
    app.show_popup(load_project)
  end;
}

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
