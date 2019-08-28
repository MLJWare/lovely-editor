local Images                  = require "Images"
local pleasure                = require "pleasure"
local fontstore               = require "fontstore"
local font_writer             = require "util.font_writer"
local clamp                   = require "math.clamp"
local signum                  = require "math.signum"
local list_join               = require "util.list.join"
local try_invoke              = require ("pleasure.try").invoke

local is_table = pleasure.is.table
local is_non_negative = pleasure.is.non_negative_number

local OFFSET_X = 2
local OFFSET_Y = 2

local SLIDER_W = 10
local FILESLOT_H = 18
local FILESLOT_HH = FILESLOT_H/2

local FileViewer = {
  font = fontstore.default[12];
}
FileViewer.__index = FileViewer

setmetatable(FileViewer, {
  __call = function (_, field)
    assert(is_table(field), "FileViewer constructor must be a table.")
    assert(is_non_negative(field.size_x),
      "Error in FileViewer constructor: Invalid property: 'size_x' must be a non-negative number.")
    assert(is_non_negative(field.size_y),
      "Error in FileViewer constructor: Invalid property: 'size_y' must be a non-negative number.")
    setmetatable(field, FileViewer)
    field._current_offset = 0
    field._current_selection = 0
    return field
  end;
})

function FileViewer:set_content (dirs, files)
  self._current_offset = 0
  self._current_selection = 0
  self._current_dirs = dirs
  self._current_files = files
  self._current_content = list_join(dirs, files)
end

function FileViewer:draw ()
  local size_x = self.size_x
  local size_y = self.size_y

  love.graphics.setLineStyle("rough")
  love.graphics.setColor(0.9, 0.9, 0.9)
  love.graphics.rectangle("fill", 0, 0, size_x, size_y)
  love.graphics.setColor(0.7, 0.7, 0.7)

  local x1 = OFFSET_X
  local y1 = OFFSET_Y
  local w1 = size_x - 3 - SLIDER_W
  local h1 = size_y - 3
  love.graphics.rectangle("line", x1, y1, w1, h1)
  pleasure.push_region(x1, y1, w1, h1)

  local content = self._current_content
  local offset = self._current_offset
  local rows = math.min(#content - offset, math.ceil(h1/FILESLOT_H))
  do
    local selection = self._current_selection - offset
    for i = 1, rows do
      local dy = (i-1)*FILESLOT_H
      love.graphics.rectangle((i == selection) and "fill" or "line", 0, dy, w1, FILESLOT_H)
    end
  end

  local folder_count = #self._current_dirs
  love.graphics.setColor(0.2, 0.2, 0.2)
  for i = 1, rows do
    local y = i*FILESLOT_H - FILESLOT_HH
    local index = i + offset
    Images.draw(index <= folder_count and "icon.folder" or "icon.document", FILESLOT_HH, y)
    font_writer.print_aligned(self.font, content[index] or "", FILESLOT_H, y, "left", "center")
  end
  pleasure.pop_region()
end

function FileViewer:mousepressed (_, my)
  local row = 1 + math.floor(((my - OFFSET_Y)/FILESLOT_H)) + self._current_offset
  local already_selected = self._current_selection == row
  self._current_selection = row
  local item = self._current_content[row]
  if not item then return end

  return try_invoke(self, self._current_dirs[row] and "on_select_folder" or  "on_select_file", item, already_selected)
end

function FileViewer:wheelmoved (_, wy)
    self._current_offset = clamp(self._current_offset - signum(wy), 0, #self._current_content - 1)
end




return FileViewer
