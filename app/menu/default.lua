local app                     = require "app"
local MenuListFrame           = require "frame.MenuList"
local LoadFileFrame           = require "frame.LoadFile"
local SaveFileFrame           = require "frame.SaveFile"
local YesNoCancelFrame        = require "frame.YesNoCancel"
local new_view_menu           = require "menu.new_view"
local sandbox                 = require "util.sandbox"
local Project                 = require "Project"
local load_data               = require "util.file.load_data"

local load_as_view = LoadFileFrame{
  on_load = function (_, file, filename)
    local data, format = load_data(file)
    if not data then
      error(("Couldn't load file %q; perhaps it isn't an image/text file?"):format(filename))
    end

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

local function load_imagedata(encoded)
  return love.image.newImageData(love.data.decode("data", "base64", encoded))
end

local load_project = LoadFileFrame {
  on_load = function (_, file, filename)
    local success, code
    if file:open("r") then
      local data = file:read()
      file:close()

      if filename:find("%.lp_raw$") then
        success, code = true, data
      else
        success, code = pcall(love.data.decompress, "string", "lz4", data)
      end
    end

    if success and code then
      local _, project = sandbox(code, {
        -- math frames
        NumberFrame      = require "frame.math.Number";
        IntegerFrame     = require "frame.math.Integer";
        MultiplyFrame    = require "frame.math.Multiply";
        DivideFrame      = require "frame.math.Divide";
        ModuloFrame      = require "frame.math.Modulo";
        SubtractFrame    = require "frame.math.Subtract";
        SumFrame         = require "frame.math.Sum";
        TickerFrame      = require "frame.math.Ticker";
        TimerFrame       = require "frame.math.Timer";
        -- other frames
        ColorPickerFrame = require "frame.ColorPicker";
        LoveFrame        = require "frame.Love";
        PixelFrame       = require "frame.Pixel";
        SliderFrame      = require "frame.Slider";
        ShaderFrame      = require "frame.Shader";
        TextBufferFrame  = require "frame.TextBuffer";
        ToolboxFrame     = require "frame.Toolbox";
        ViewGroupFrame   = require "frame.ViewGroup";
        TimelineFrame    = require "frame.Timeline";
        ConditionalFrame = require "frame.Conditional";
        -- other stuff
        Vector2         = require "linear-algebra.Vector2";
        Viewport        = require "Viewport";
        View            = require "View";
        Ref             = require "Ref";
        Project         = Project;
        imagedata       = load_imagedata;
      })
      if Project.is(project) then
        project:prepare(app)
        app.project = project
        return
      else print(_, project)
      end
    end


    error(("Invalid project file: %s"):format(filename))
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
