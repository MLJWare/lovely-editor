local save_project            = require "dialog.save_project"
local load_project            = require "dialog.load_project"
local app                     = require "app"
local SaveFileFrame           = require "frame.SaveFile"

return SaveFileFrame {
  action = save_project.action;
  on_saved = function ()
    app.show_popup(load_project)
  end;
}
