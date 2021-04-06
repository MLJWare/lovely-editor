local app = require "app"
local NewSizedViewFrame = require "frame.NewPixelView"

return function (option, _)
  local popup_x, popup_y = app.popup_position_as_local()
  app.show_popup (NewSizedViewFrame {
    create_pos_x = popup_x;
    create_pos_y = popup_y;
    create_new_frame = option.create_new_frame;
    title = option.text
  })
end
