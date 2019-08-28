local app                     = require "app"
local LoadFileFrame           = require "frame.LoadFile"
local try_create_project      = require "internal.try_create_project"

return LoadFileFrame {
  on_load = function (_, filename, filedata)
    if filedata then
      local project, msg = try_create_project(filedata, filename)

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
