local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local IntegerFrame            = require "frame.math.Integer"
local NumberFrame             = require "frame.math.Number"
local SumFrame                = require "frame.math.Sum"
local MultiplyFrame           = require "frame.math.Multiply"
local DivideFrame             = require "frame.math.Divide"
local ModuloFrame             = require "frame.math.Modulo"
local SubtractFrame           = require "frame.math.Subtract"
local TimerFrame              = require "frame.math.Timer"
local TickerFrame             = require "frame.math.Ticker"

return MenuListFrame {
  options = {
    {
      text   = "New Integer View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = IntegerFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Number View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = NumberFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Multiply View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = MultiplyFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Divide View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = DivideFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Modulo View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = ModuloFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Sum View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = SumFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Subtract View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = SubtractFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Timer View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = TimerFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Ticker View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view(View{
          frame = TickerFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    { text = "Cancel"; }
  };
}
