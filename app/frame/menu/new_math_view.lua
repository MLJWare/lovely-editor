local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local IntegerFrame            = require "frame.Integer"
local NumberFrame             = require "frame.Number"
local SumFrame                = require "frame.Sum"
local TimerFrame              = require "frame.Timer"

return MenuListFrame {
  options = {
    {
      text   = "New Integer View";
      action = function (_, _)
        app.add_view(View{
          frame = IntegerFrame {};
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Number View";
      action = function (_, _)
        app.add_view(View{
          frame = NumberFrame {};
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Sum View";
      action = function (_, _)
        app.add_view(View{
          frame = SumFrame {};
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Timer View";
      action = function (_, _)
        app.add_view(View{
          frame = TimerFrame {};
          pos = app.popup_position();
        })
      end;
    };
    { text = "Cancel"; }
  };
}