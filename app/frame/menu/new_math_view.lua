local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local IntegerFrame            = require "frame.math.Integer"
local NumberFrame             = require "frame.math.Number"
local SumFrame                = require "frame.math.Sum"
local MultiplyFrame           = require "frame.math.Multiply"
local DivideFrame             = require "frame.math.Divide"
local SubtractFrame           = require "frame.math.Subtract"
local TimerFrame              = require "frame.math.Timer"
local TickerFrame             = require "frame.math.Ticker"

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
      text   = "New Multiply View";
      action = function (_, _)
        app.add_view(View{
          frame = MultiplyFrame {};
          pos = app.popup_position();
        })
      end;
    };
    {
      text   = "New Divide View";
      action = function (_, _)
        app.add_view(View{
          frame = DivideFrame {};
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
      text   = "New Subtract View";
      action = function (_, _)
        app.add_view(View{
          frame = SubtractFrame {};
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
    {
      text   = "New Ticker View";
      action = function (_, _)
        app.add_view(View{
          frame = TickerFrame {};
          pos = app.popup_position();
        })
      end;
    };
    { text = "Cancel"; }
  };
}
