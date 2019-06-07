local app                     = require "app"
local View                    = require "View"
local MenuListFrame           = require "frame.MenuList"
local RotationFrame           = require "frame.Rotation"
local AnglesFrame             = require "frame.Angles"
local Vector2Frame            = require "frame.Vector2"
local VectorSplitFrame        = require "frame.VectorSplit"
local GraphFrame              = require "frame.Graph"
local ConditionalFrame        = require "frame.Conditional"
local SliderFrame             = require "frame.Slider"

return MenuListFrame {
  options = {
    {
      text   = "New Slider View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = SliderFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Rotation View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = RotationFrame {
            size_x = 64;
            size_y = 64;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Angles View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = AnglesFrame {
            size_x = 64;
            size_y = 64;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Graph View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = GraphFrame {
            size_x = 64;
            size_y = 64;
          };
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New VectorSplit View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = VectorSplitFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Vector2 View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = Vector2Frame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    {
      text   = "New Conditional View";
      action = function (_, _)
        local popup_x, popup_y = app.popup_position_as_local()
        app.add_view (View {
          frame = ConditionalFrame {};
          pos_x = popup_x;
          pos_y = popup_y;
        })
      end;
    };
    { text = "Cancel"; }
  };
}
