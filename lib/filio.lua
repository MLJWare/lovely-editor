--- Basic File I/O in LÖVE for Windows and MacOS
--- Adapted from https://github.com/linux-man/lovefs

local ffi = require("ffi")

local FileSystem = {}
FileSystem.__index = FileSystem

local SEPARATOR = package.config:sub(1,1)
local DOT_SEPARATOR = "."..SEPARATOR
local SEPARATOR_DOT_DOT = SEPARATOR..".."
local DOUBLE_SEPARATOR = SEPARATOR..SEPARATOR
local PATTERN_DIR = ("(.*%s)"):format(SEPARATOR)

if love.system.getOS() == "Windows" then
  ffi.cdef[[
    #pragma pack(push)
    #pragma pack(1)
    struct WIN32_FIND_DATAW {
      uint32_t dwFileWttributes;
      uint64_t ftCreationTime;
      uint64_t ftLastAccessTime;
      uint64_t ftLastWriteTime;
      uint32_t dwReserved[4];
      char cFileName[520];
      char cAlternateFileName[28];
    };
    #pragma pack(pop)

    void* FindFirstFileW(const char* pattern, struct WIN32_FIND_DATAW* fd);
    bool FindNextFileW(void* ff, struct WIN32_FIND_DATAW* fd);
    bool FindClose(void* ff);
    bool CopyFileW(const char* src, const char* dst, bool bFailIfExists);
    int GetLogicalDrives(void);

    int MultiByteToWideChar(unsigned int CodePage, uint32_t dwFlags, const char* lpMultiByteStr,
      int cbMultiByte, const char* lpWideCharStr, int cchWideChar);
    int WideCharToMultiByte(unsigned int CodePage, uint32_t dwFlags, const char* lpWideCharStr,
      int cchWideChar, const char* lpMultiByteStr, int cchMultiByte,
      const char* default, int* used);
  ]]
  local WIN32_FIND_DATA = ffi.typeof('struct WIN32_FIND_DATAW')
  local INVALID_HANDLE = ffi.cast('void*', -1)

  local function u2w(str, code)
    local size = ffi.C.MultiByteToWideChar(code or 65001, 0, str, #str, nil, 0)
    local buf = ffi.new("char[?]", size * 2 + 2)
    ffi.C.MultiByteToWideChar(code or 65001, 0, str, #str, buf, size * 2)
    return buf
  end

  local function w2u(wstr, code)
    local size = ffi.C.WideCharToMultiByte(code or 65001, 0, wstr, -1, nil, 0, nil, nil)
    local buf = ffi.new("char[?]", size + 1)
    ffi.C.WideCharToMultiByte(code or 65001, 0, wstr, -1, buf, size, nil, nil)
    return ffi.string(buf)
  end

  local function removeValue(tb, value)
    for n = #tb, 1, -1 do
      if value == 'hidden' then
        if tb[n]:match('^%..') then table.remove(tb, n) end
      else
        if tb[n] == value then table.remove(tb, n) end
      end
    end
  end

  -- Windows
  function FileSystem:full_path(path)
    if path == '.' then path = self.current end
    if (path:sub(1,2) == DOT_SEPARATOR) then path = self.current..path:sub(2) end
    if not (path:sub(2,2) == ':') then path = ("%s%s%s"):format(self.current, SEPARATOR, path) end
    path = path:gsub('/', SEPARATOR)
    path = path:gsub(DOUBLE_SEPARATOR, SEPARATOR)
    if path:sub(-3) == SEPARATOR_DOT_DOT then
      path = path:sub(1, -4)
      path = path:match(PATTERN_DIR) or path
    end
    if #path > 1 and path:sub(-1) == SEPARATOR then
      path = path:sub(1, -2)
    end
    return path
  end

  -- Windows
  function FileSystem:ls(dir)
    dir = self:full_path(dir or self.current)
    local dirs = {}
    local files = {}
    local fd = ffi.new(WIN32_FIND_DATA)
    local filehandle = ffi.C.FindFirstFileW(u2w(dir..'\\*'), fd)
    ffi.gc(filehandle, ffi.C.FindClose)
    if filehandle ~= INVALID_HANDLE then
      repeat
        local fn = w2u(fd.cFileName)
        if fd.dwFileWttributes == 16
        or fd.dwFileWttributes == 17
        or (self.showHidden and fd.dwFileWttributes == 8210) then
          table.insert(dirs, fn)
        elseif fd.dwFileWttributes == 32 then
          table.insert(files, fn)
        end
      until not ffi.C.FindNextFileW(filehandle, fd)
    end
    ffi.C.FindClose(ffi.gc(filehandle, nil))
    if #dirs == 0 then return false end
    removeValue(dirs, '.')
    removeValue(dirs, '..')
    if #dir > 3 then
      table.insert(dirs, "..")
    end
    if not self.showHidden then removeValue(dirs, 'hidden') end
    table.sort(dirs)
    if self.filter then
      for n = #files, 1, -1 do
        local ext = files[n]:match('[^.]+$')
        local valid = false
        for _, v in ipairs(self.filter) do
          valid = valid or (ext == v)
        end
        if not (valid) then table.remove(files, n) end
      end
    end
    if not self.showHidden then removeValue(files, 'hidden') end
    table.sort(files)

    return dir, dirs, files
  end

  -- Windows
  function FileSystem:_update_drives()
    local drives = {}
    local aCode = string.byte('A')
    local drv = ffi.C.GetLogicalDrives()
    for n = 0, 15, 1 do
      if not(drv % 2 == 0) then table.insert(drives, string.char(aCode + n)..':\\') end
      drv = math.floor(drv / 2)
    end
    self.drives = drives
  end

  -- Windows
  function FileSystem.copy(from_path, to_path)
    ffi.C.CopyFileW(u2w(from_path), u2w(to_path), false)
  end
else -- Posix
  ffi.cdef[[
    struct dirent {
      unsigned long  d_ino;       /* inode number */
      unsigned long  d_off;       /* not an offset */
      unsigned short d_reclen;    /* length of this record */
      unsigned char  d_type;      /* type of file; not supported by all filesystem types */
      char           d_name[256]; /* filename */
    };

    struct DIR *opendir(const char *name);
    struct dirent *readdir(struct DIR *dirstream);
    int closedir (struct DIR *dirstream);
  ]]

  local function removeValue(tb, value)
    for n = #tb, 1, -1 do
      if value == 'hidden' then
        if tb[n]:match('^%..') then table.remove(tb, n) end
      else
        if tb[n] == value then table.remove(tb, n) end
      end
    end
  end

  -- Posix
  function FileSystem:full_path(path)
    if path == '.' then path = self.current end
    if (path:sub(1,2) == DOT_SEPARATOR) then path = self.current..path:sub(2) end
    if not (path:sub(1,1) == '/') then path = ("%s%s%s"):format(self.current, SEPARATOR, path) end
    path = path:gsub('\\', SEPARATOR)
    path = path:gsub(DOUBLE_SEPARATOR, SEPARATOR)
    if path:sub(-3) == SEPARATOR_DOT_DOT then
      path = path:sub(1, -4)
      path = path:match(PATTERN_DIR) or path
    end
    if #path > 1 and path:sub(-1) == SEPARATOR then
      path = path:sub(1, -2)
    end
    return path
  end

  -- Posix
  function FileSystem:ls(dir)
    dir = self:full_path(dir or self.current)
    local dirs, files = {}, {}
    local hDir = ffi.C.opendir(dir)
    ffi.gc(hDir, ffi.C.closedir)
    if hDir ~= nil then
      local dirent = ffi.C.readdir(hDir)
      while dirent ~= nil do
        local fn = ffi.string(dirent.d_name)
        if dirent.d_type == 4 then
          table.insert(dirs, fn)
        elseif dirent.d_type == 8 then
          table.insert(files, fn)
        end
        dirent = ffi.C.readdir(hDir)
      end
    end
    ffi.C.closedir(ffi.gc(hDir, nil))
    if #dirs == 0 then return false end
    removeValue(dirs, '.')
    if #dir == 1 then
      removeValue(dirs, '..')
    end
    if not self.showHidden then removeValue(dirs, 'hidden') end
    table.sort(dirs)
    if self.filter then
      for n = #files, 1, -1 do
        local ext = files[n]:match('[^.]+$')
        local valid = false
        for _, v in ipairs(self.filter) do
          valid = valid or (ext == v)
        end
        if not (valid) then table.remove(files, n) end
      end
    end
    if not self.showHidden then removeValue(files, 'hidden') end
    table.sort(files)

    return dir, dirs, files
  end

  -- Posix
  function FileSystem:cd(dir)
    local current, dirs, files = self:ls(dir)
    if current then
      self.current = current
      self.dirs = dirs
      self.files = files
      return true
    end
    return false
  end

  -- Posix
  if ffi.os == "Linux" then
    function FileSystem:_update_drives()
      local drives = {}
      local dir, dirs = self:ls('/media')
      if dir then
        for n, _ in ipairs(dirs) do dirs[n] = '/media/'..dirs[n] end
        drives = dirs
      end
      table.insert(drives, 1, '/')
      self.drives = drives
    end
  else
    function FileSystem:_update_drives()
      local drives = {}
      local dir, dirs = self:ls('/Volumes')
      if dir then
        for n, _ in ipairs(dirs) do dirs[n] = '/Volumes/'..dirs[n] end
        drives = dirs
      end
      table.insert(drives, 1, '/')
      self.drives = drives
    end
  end

  -- Posix
  function FileSystem.copy(from_path, to_path)
    local from = io.open(from_path, "rb")
    local data = from:read("*all")
    from:close()
    local to = io.open(to_path, "wb")
    to:write(data)
    to:close()
  end
end

local ROOT_DIR = ("c:%s"):format(SEPARATOR)
local HOME_DIR = love.filesystem.getUserDirectory()

function FileSystem:switchHidden()
  self.showHidden = not self.showHidden
  self:cd()
end

function FileSystem:setFilter(filter)
  self.filter = nil
  if type(filter) == "table" then
    self.filter = filter
  elseif type(filter) == "string" then
    local t = {}
    local f = filter:sub((filter:find('|') or 0) + 1)
    for i in string.gmatch(f, "%S+") do
      i = i:gsub('[%*%.%;]', '')
      if i ~= '' then table.insert(t, i) end
    end
    if #t > 0 then self.filter = t end
  end
  self:cd()
end

function FileSystem:cd(dir)
  local current, dirs, files = self:ls(dir)
  if current then
    self.current = current
    self.dirs = dirs
    self.files = files
    return true
  end
  return false
end

function FileSystem:up()
  self:cd(self.current:match(PATTERN_DIR))
end

local function findValue(tb, value)
  for i = 1, #tb do
    if tb[i] == value then return true end
  end
  return false
end

local PATTERN_NAME = ("[^%s]+$"):format(SEPARATOR)
function FileSystem:exists(path)
  path = self:full_path(path)
  local dir = self:full_path(path:match(PATTERN_DIR))
  local name = path:match(PATTERN_NAME)
  local dirs, files
  dir, dirs, files = self:ls(dir)
  if dir then
    local is_dir = findValue(dirs, name)
    local is_file = findValue(files, name)
    return is_dir or is_file, is_dir, is_file
  end
  return false
end

function FileSystem:isDirectory(path)
  local exists, isDir = self:exists(path)
  return exists and isDir or false
end

function FileSystem:isFile(path)
  local exists, _, is_file = self:exists(path)
  return exists and is_file or false
end

function FileSystem:load(path)
  local file = io.open(self:full_path(path), "rb")
  local data = file:read("*all")
  file:close()
  return love.filesystem.newFileData(data, path)
end

function FileSystem:write(path, data)
  local file = io.open(self:full_path(path), "wb")
  if type(data) ~= "string" then
    data = data:getString()
  end
  file:write(data)
  file:close()
  return true
end

function FileSystem.file_extension(path)
  return path:match(PATTERN_NAME):match('[^.]+$') or ""
end

function FileSystem.new(dir)
  dir = dir or ROOT_DIR
  local fs = setmetatable({
    selectedFile = nil;
    filter = nil;
    showHidden = true;
    current = dir;
  }, FileSystem)
  if not fs:cd(dir) then
    --if not fs:cd(HOME_DIR) then
      fs:cd(ROOT_DIR)
    --end
  end
  fs:_update_drives()
  return fs
end

return FileSystem
