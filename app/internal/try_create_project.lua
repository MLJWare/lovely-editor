local sandbox                 = require "util.sandbox"
local Project                 = require "Project"

local function load_imagedata(encoded)
  return love.image.newImageData(love.data.decode("data", "base64", encoded))
end

return function (filedata, filename)
  local success, code
  if filename:find("%.lp_raw$") then
    success, code = true, filedata
  else
    success, code = pcall(love.data.decompress, "string", "lz4", filedata)
  end

  if not success then return nil, code end

  local _, project = sandbox(code, {
      -- math frames
      NumberFrame = require "frame.math.Number";
      IntegerFrame = require "frame.math.Integer";
      MultiplyFrame = require "frame.math.Multiply";
      DivideFrame = require "frame.math.Divide";
      ModuloFrame = require "frame.math.Modulo";
      SubtractFrame = require "frame.math.Subtract";
      SumFrame = require "frame.math.Sum";
      TickerFrame = require "frame.math.Ticker";
      TimerFrame = require "frame.math.Timer";
      -- graphics frames
      ColorPickerFrame = require "frame.ColorPicker";
      PixelFrame = require "frame.Pixel";
      ShaderFrame = require "frame.Shader";
      ParticlesFrame = require "frame.Particles";
      ToolboxFrame = require "frame.Toolbox";
      TimelineFrame = require "frame.Timeline";
      -- control frames
      SliderFrame = require "frame.Slider";
      Vector2Frame = require "frame.Vector2";
      VectorSplitFrame = require "frame.VectorSplit";
      RotationFrame = require "frame.Rotation";
      AnglesFrame = require "frame.Angles";
      GraphFrame = require "frame.Graph";
      ConditionalFrame = require "frame.Conditional";
      -- other frames
      LoveFrame = require "frame.Love";
      TextBufferFrame = require "frame.TextBuffer";
      ViewGroupFrame = require "frame.ViewGroup";
      -- other stuff
      Viewport = require "Viewport";
      View = require "View";
      Ref = require "Ref";
      Project = Project;
      imagedata = load_imagedata;
  })
  if Project.is(project) then
    return project
  else
    return nil, project
  end
end
