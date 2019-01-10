local app                     = require "app"
local clone                   = require "util.clone"
local SaveFileFrame           = require "frame.SaveFile"
local YesNoFrame              = require "frame.YesNo"
local MenuListFrame           = require "frame.MenuList"
local PixelFrame              = require "frame.Pixel"

local function is_pixelframe (_, menu)
  return PixelFrame.is(menu.view.frame)
end;

local save_file = SaveFileFrame{
  data   = nil;
  action = nil;
  on_saved = function (self)
    self.action = nil
    self.data   = nil
  end
}

local ask_destroy = YesNoFrame{
  title = "Destroy?";
  text  = "";
  _view = nil;
  option_yes = function (self)
    app.remove_view(self._view)
    self._view = nil
  end;
  option_no = function (self)
    self._view = nil
  end;
}

return MenuListFrame {
  view = nil;
  options = {
    {
      text   = "Save Frame to File";
      action = function (_, menu)
        local frame = menu.view.frame;
        local action = frame:check_action("core:save")
        if type(action) == "function" then
          save_file.action = action
          save_file.data   = frame
          app.show_popup(save_file)
        end
      end;
      condition = function (_, menu)
        return menu.view.frame:check_action("core:save");
      end
    };
    {
      text   = "Clone View (using same Frame)";
      action = function (_, menu)
        app.add_view(1, {
          frame = menu.view.frame;
          pos   = app.project.viewport:global_to_local_pos(menu.view.pos + 10);
          scale = menu.view.scale;
        })
      end;
      condition = is_pixelframe;
    };
    {
      text   = "Clone View and Frame";
      action = function (_, menu)
        app.add_view(1, {
          frame = clone(menu.view.frame);
          pos   = app.project.viewport:global_to_local_pos(menu.view.pos + 10);
          scale = menu.view.scale;
        })
      end;
      condition = is_pixelframe;
    };
    {
      text   = "Destroy View (cannot be undone)";
      action = function (_, menu)
        ask_destroy.text = ("Are you sure you want to destroy this view? (id: %s)"):format(menu.view.frame:id())
        ask_destroy._view = menu.view
        app.show_popup(ask_destroy)
      end;
    };
    { text = "Cancel"; }
  };
}
