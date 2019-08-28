local app                     = require "app"
local Button                  = require "Button"
local pack_color              = require "util.color.pack"
local EditableText            = require "EditableText"
local FileViewer              = require "FileViewer"
local element_contains        = require "util.element_contains"
local Frame                   = require "Frame"
local Images                  = require "Images"
local pleasure                = require "pleasure"
local YesNoFrame              = require "frame.YesNo"
local filio                   = require "filio".new()

local try_invoke = pleasure.try.invoke

local is_table = pleasure.is.table
local is_metakind = pleasure.is.metakind

local SaveFileFrame = {}
SaveFileFrame.__index = SaveFileFrame
SaveFileFrame._kind = ";SaveFileFrame;Frame;"

local PAD_X    = 6
local PAD_Y    = 5
local OFFSET_Y = PAD_Y + 19

local VBAR_X = 128
local HBAR1_y = 45
local BOOKMARKS_X = PAD_X
local BOOKMARKS_Y = HBAR1_y + 4
local FILEVIEW_X = VBAR_X + PAD_X
local FILEVIEW_Y = HBAR1_y + PAD_Y + 1

local BTN_W = 84
local BTN_H = 20
local btn_text_color = pack_color(0.2, 0.2, 0.2, 1.0)

local TEXTBAR_H = BTN_H

setmetatable(SaveFileFrame, {
  __index = Frame;
  __call  = function (_, frame)
    assert(is_table(frame), "SaveFileFrame constructor must be a table.")
    frame.size_x = math.max(frame.size_x or 600, 400)
    frame.size_y = math.max(frame.size_y or 380, 200)
    SaveFileFrame.typecheck(frame, "SaveFileFrame constructor")

    frame._current_path = love.filesystem.getSaveDirectory()

    local edit_path = EditableText{
      text = "";
      size_x = 0;
      size_y = TEXTBAR_H;
      hint = "path";
    }
    frame._edit_path = edit_path

    local bookmarks = EditableText{
      text = "";
      size_x = 0;
      size_y = 0;
      hint = "bookmarks";
    }
    frame._bookmarks = bookmarks

    local fileview = FileViewer {
      size_x = 0;
      size_y = 0;
      on_select_folder = function (_, folder, already_selected)
        if not already_selected then return end
        frame:_open_folder(folder)
      end;
      on_select_file = function (_, filename, already_selected)
        frame._edit_filename.text = filename
        if not already_selected then return end
        frame._btn_yes:mouseclicked()
      end;
    }
    frame._fileview = fileview

    local edit_filename = EditableText{
      text = "";
      size_x = 0;
      size_y = TEXTBAR_H;
      hint = "filename";
    }
    frame._edit_filename = edit_filename

    local btn_filter = Button {
      text = "F";
      size_x = BTN_H; -- using height is intentional
      size_y = BTN_H;
      text_color = btn_text_color;
      mouseclicked = function ()
        print("change filter") -- TODO
      end;
    }
    frame._btn_filter = btn_filter

    local btn_yes = Button {
      text = "Save";
      size_x = BTN_W;
      size_y = BTN_H;
      text_color = btn_text_color;
      mouseclicked = function ()
        local filename = edit_filename.text
        local directory_path = frame._current_path
        local full_path = ("%s/%s"):format(directory_path, filename)
        if #filename == 0 or not filio:isDirectory(directory_path) then
          --TODO show message stating why the file wasn't saved!
          return
        elseif filio:isFile(full_path) then
          app.show_popup(YesNoFrame {
            title = "Override?";
            text  = (("File %q already exists. Override?"):format(filename));
            option_yes = function ()
              frame:_save_and_close(filename, full_path)
            end;
          })
        else
          frame:_save_and_close(filename, full_path)
        end
      end;
    }
    frame._btn_yes = btn_yes

    local btn_no = Button {
      text = "Cancel";
      size_x = BTN_W;
      size_y = BTN_H;
      text_color = btn_text_color;
      mouseclicked = function ()
        frame:close()
      end;
    }
    frame._btn_no = btn_no

    local ui = { edit_path, bookmarks, fileview, edit_filename, btn_filter, btn_yes, btn_no }
    frame._ui = ui

    frame._pressed_index = nil

    setmetatable(frame, SaveFileFrame)

    frame:_calc_bounds()
    frame:_load_path_directory(frame._current_path)

    return frame
  end;
})

function SaveFileFrame.typecheck(obj, where)
  Frame.typecheck(obj, where)
end

function SaveFileFrame.is(obj)
  return is_metakind(obj, ";SaveFileFrame;")
end

function SaveFileFrame:_open_folder(folder)
  self:_load_path_directory(("%s/%s"):format(self._current_path, folder))
end

function SaveFileFrame:_save_and_close(filename, full_path)
  local data = self.action(self.data, filename)
  filio:write(full_path, data)
  try_invoke(self, "on_saved")
  self:close()
end

function SaveFileFrame:draw(size_x, size_y)
  Images.ninepatch("menu", 0, 16, size_x, size_y - 16)

  local hbar2_y = self._hbar2_y

  Images.hbar("popup-bars-2-1", 2, HBAR1_y, size_x - 5)
  Images.hbar("popup-bars-2-1", 2, hbar2_y, size_x - 5)
  Images.vbar("popup-bars-1-2", VBAR_X, HBAR1_y + 2, hbar2_y - HBAR1_y - 1)

  Images.ninepatch("menu", 0,  0, size_x, 20)
  love.graphics.print("Save As:", 6, 4)

  do
    local filter_x = PAD_X
    local filter_y = self._filterbar_y
    local filter_w = self._filterbar_w
    local filter_h = BTN_H
    pleasure.push_region(filter_x, filter_y, filter_w, filter_h)
    love.graphics.setColor(0.75, 0.75, 0.75)
    love.graphics.rectangle("fill", 0, 0, filter_w, filter_h)
    pleasure.pop_region()
  end

  local ui = self._ui
  for i = 1, #ui do
    pleasure.push_region(self:_element_bounds(i))
    love.graphics.setColor(1, 1, 1)
    try_invoke(ui[i], "draw", self)
    pleasure.pop_region()
  end
end

function SaveFileFrame:_calc_bounds()
  local size_x = self.size_x
  local size_y = self.size_y

  self._path_w = size_x - 2*PAD_X
  self._edit_path.size_x = self._path_w

  self._hbar2_y = size_y - 3*PAD_Y - 2*BTN_H - 2

  self._bookmarks_w = 10 -- TODO
  self._bookmarks_h = 10 -- TODO

  self._fileview.size_x = size_x - VBAR_X - 2*PAD_X
  self._fileview.size_y = size_y - 5*PAD_Y - 2*BTN_H - HBAR1_y

  self._filename_y = size_y - 2*PAD_Y - 2*BTN_H - 2
  self._filename_w = size_x - BTN_W - 3*PAD_X
  self._edit_filename.size_x = self._filename_w

  self._filterbar_y = size_y - PAD_Y - BTN_H - 2
  self._filterbar_w = size_x - 4*PAD_X - BTN_W - BTN_H

  self._filter_btn_x = self._filterbar_w + 2*PAD_X
  self._filter_btn_y = self._filterbar_y

  self._load_btn_x = self.size_x - PAD_X - BTN_W
  self._load_btn_y = self.size_y - 2*PAD_Y - 2*BTN_H - 2

  self._cancel_btn_x = self.size_x - PAD_X - BTN_W
  self._cancel_btn_y = self.size_y - PAD_Y - BTN_H - 2
end

function SaveFileFrame:_element_bounds(index)
  if index == 1 then
    -- path
    return PAD_X, OFFSET_Y, self._path_w, BTN_H
  elseif index == 2 then
    -- bookmarks
    return BOOKMARKS_X, BOOKMARKS_Y, self._bookmarks_w, self._bookmarks_h
  elseif index == 3 then
    -- files view
    local fileview = self._fileview
    return FILEVIEW_X, FILEVIEW_Y, fileview.size_x, fileview.size_y
  elseif index == 4 then
    -- filename
    return PAD_X, self._filename_y, self._filename_w, TEXTBAR_H
  elseif index == 5 then
    -- filter button
    return self._filter_btn_x, self._filter_btn_y, BTN_H, BTN_H
  elseif index == 6 then
    -- load button
    return self._load_btn_x, self._load_btn_y, BTN_W, BTN_H
  elseif index == 7 then
    -- cancel button
    return self._cancel_btn_x, self._cancel_btn_y, BTN_W, BTN_H
  end
end

function SaveFileFrame:init_popup()
  self:request_focus()

  local ui = self._ui
  for i = 1, #ui do
    ui[i].focused = false
  end

  self:_load_path_directory(self._edit_path.text)
end

function SaveFileFrame:wheelmoved(wx, wy)
  self._fileview:wheelmoved(wx, wy)
end

function SaveFileFrame:mousepressed(mx, my, button)
  self:request_focus()

  local searching = true
  local ui = self._ui
  for index = 1, #ui do
    local element = ui[index]
    if searching then
      local x, y = self:_element_bounds(index)
      local mx2, my2 = mx - x, my - y
      if element_contains(element, mx2, my2) then
        self._pressed_index = index
        element.pressed = true
        element.focused = true
        searching = false
        try_invoke(element, "mousepressed", mx2, my2, button)
      else
        element.focused = false
      end
    else
      element.focused = false
    end
  end
end

function SaveFileFrame:mousemoved(mx, my)
  for index, element in ipairs(self._ui) do
    local x, y = self:_element_bounds(index)
    local mx2, my2 = mx - x, my - y
    if element_contains(element, mx2, my2) then
      if not element.hovered then
        try_invoke(element, "mouseenter", mx2, my2)
        element.hovered = true
      end
      return try_invoke(element, "mousemoved", mx2, my2)
    elseif element.hovered then
      try_invoke(element, "mouseexit", mx2, my2)
      element.hovered = false
    end
  end
end

function SaveFileFrame:mousedragged1(mx, my)
  local index = self._pressed_index
  if not index then return end
  local x, y = self:_element_bounds(index)
  try_invoke(self._ui[index], "mousedragged1", mx - x, my - y)
end

function SaveFileFrame:mousereleased(mx, my, button)
  local index = self._pressed_index
  if index then
    self._pressed_index = nil
    local x, y = self:_element_bounds(index)
    local element = self._ui[index]
    local mx2, my2 = mx - x, my - y
    try_invoke(element, "mousereleased", mx2, my2, button)
    if element.pressed and element_contains(element, mx2, my2) then
      try_invoke(element, "mouseclicked", mx2, my2, button)
    end
  end

  for _, element in ipairs(self._ui) do
    element.pressed = false
  end
end

function SaveFileFrame:_load_path_directory(path)
  local dir, dirs, files = filio:ls(path)
  self._edit_path.text = dir or self._current_path
  self._edit_path:_set_caret(math.huge)
  if not dir then return end
  self._current_path = dir
  self._fileview:set_content(dirs, files)
end

function SaveFileFrame:keypressed(key, scancode, isrepeat)
  if key == "tab" then
    if self._edit_path.focused then
      self._edit_path.focused = false
      self._edit_filename.focused = true
      self._edit_filename:_set_caret(math.huge)
    else
      self._edit_path.focused = true
      self._edit_path:_set_caret(math.huge)
      self._edit_filename.focused = false
    end
  elseif key == "return" then
    if self._edit_path.focused then
      self:_load_path_directory(self._edit_path.text)
    else
      try_invoke(self._btn_yes, "mouseclicked")
    end
  elseif key == "escape" then
    try_invoke(self._btn_no, "mouseclicked")
  elseif self._edit_path.focused then
    self._edit_path:keypressed(key, scancode, isrepeat)
  elseif self._edit_filename.focused then
    self._edit_filename:keypressed(key, scancode, isrepeat)
  end
end

function SaveFileFrame:textinput(text)
  if self._edit_path.focused then
    self._edit_path:textinput(text)
  elseif self._edit_filename.focused then
    self._edit_filename:textinput(text)
  end
end

function SaveFileFrame:focuslost()
  for _, element in ipairs(self._ui) do
    element.focused = false
  end
end

return SaveFileFrame
