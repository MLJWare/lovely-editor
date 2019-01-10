local Project = {}
Project.__index = Project

Project._kind = ";Project;"

setmetatable(Project, {
  __call = function (_, project)
    assert(type(project) == "table", "Project constructor must be a table.")
    Project.typecheck(project, "Project constructor")
    setmetatable(project, Project)

    return project
  end;
})

function Project:prepare(app)
  for _, view in ipairs(self.views) do
    app.focus_handler:assign(view.frame)
  end

  for to, from in pairs(self._links) do
    app.connect(from, to, true)
  end
end

function Project.typecheck(obj, where)
end

function Project.is(obj)
  local meta = getmetatable(obj)
  return type(meta) == "table"
  and type(meta._kind) == "string"
  and meta._kind:find(";Project;")
end

local function as_strings(a, ...)
  if a == nil then return end
  return tostring(a), as_strings(...)
end

local function append (t, s, ...)
  t[1 + #t] = tostring(s):format(as_strings(...))
end

function Project:serialize()
  local viewport = self.viewport
  local views    = self.views
  local links    = self._links

  local result = {}

  local view2index, views_data = {}, {}
  local frame2index, frames = {}, {}

  do -- serialize views
    for index = 1, #views do
      local view = views[index]
      view2index[view] = index
      views_data[index] = view:_serialize(frame2index, frames)
    end

    append(result, "local frames = {\n")
    -- serialize frame lookup
    for index = 1, #frames do
      append(result, "  [%d] = %s;\n", index, frames[index])
    end
    append(result, "}\n\n")

    append(result, "local views = {\n")
    -- serialize frame lookuphttps://fontstruct.com/
    for index = 1, #views_data do
      append(result, "  [%d] = %s;\n", index, views_data[index])
    end
    append(result, "}\n\n")
  end

  do -- serialize links
    append(result, "local _links = {")
    if next(links) then
      append(result, "\n")

      for to, from in pairs(links) do
        local from_view = view2index[rawget(from, "____view____")]
        local from_prop = rawget(from, "____prop____")
        local   to_view = view2index[rawget(to  , "____view____")]
        local   to_prop = rawget(to  , "____prop____")

        append(result, "  [Ref(views[%d], %q)] = Ref(views[%d], %q);\n", to_view, to_prop, from_view, from_prop)
      end
    end
    append(result, "}\n\n")
  end

  append(result, "return Project {\n")
  if viewport then
    append(result, "  viewport = %s;\n", viewport:_serialize())
  end
  append(result, [[
  frames = frames;
  views  = views;
  _links = _links;
}
]])
  return table.concat(result)
end

return Project
