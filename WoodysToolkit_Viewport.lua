--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME = ...
local MOD = LibStub("AceAddon-3.0"):GetAddon(MODNAME)
local SUBNAME = "Viewport"
local upvalues = setmetatable({}, { __index = MOD })
local SUB = MOD:NewModule(SUBNAME, upvalues, "AceConsole-3.0", "AceEvent-3.0")
setfenv(1, SUB)

--------------------------------------------------------------------------------
-- Viewport
--------------------------------------------------------------------------------

ViewportOverlay = nil
mOriginalViewport = nil

local function getCurrentScreenResolution()
  local resolution = ({_G.GetScreenResolutions()})[_G.GetCurrentResolution()]
  for width, height in string.gmatch(resolution, "(%w+)x(%w+)") do
    --     print("w="..k.." h="..v)
    return _G.tonumber(width), _G.tonumber(height)
  end
end

local function getWorldFramePoint(point)
  for ii = 1, _G.WorldFrame:GetNumPoints(), 1 do
    local apoint, relativeTo, relativePoint, xOfs, yOfs = _G.WorldFrame:GetPoint(ii)
    if point == apoint then
      return xOfs, yOfs
    end
  end
end

local function getViewpointScaling()
  local width, height = getCurrentScreenResolution()
  local scaling = 768 / height
  return scaling
end

local function setupViewport(top, bottom, left, right)
  if not ViewportOverlay then
    ViewportOverlay = _G.WorldFrame:CreateTexture(nil, "BACKGROUND")
    ViewportOverlay:SetTexture(0, 0, 0, 1)
    ViewportOverlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, 1)
    ViewportOverlay:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1, -1)
  end

  local topLeftX = left
  local topLeftY = -(top)
  local bottomRightX = -(right)
  local bottomRightY = bottom

  _G.WorldFrame:SetPoint("TOPLEFT", topLeftX, topLeftY)
  _G.WorldFrame:SetPoint("BOTTOMRIGHT", bottomRightX, bottomRightY)
end

local function saveOriginalViewport()
  if not mOriginalViewport then
    local tlX, tlY = getWorldFramePoint("TOPLEFT")
    local brX, brY = getWorldFramePoint("BOTTOMRIGHT")
    mOriginalViewport = {
      top = tlY,
      bottom = brY,
      left = tlX,
      right = brX
    }
  end
end

local function resetViewport()
  if mOriginalViewport then
    local top = -(mOriginalViewport["top"])
    local bottom = mOriginalViewport["bottom"]
    local left = mOriginalViewport["left"]
    local right = -(mOriginalViewport["right"])
    setupViewport(top, bottom, left, right)
    mOriginalViewport = nil
  end
end

local function applyViewport()
  if db.profile.viewport.enable then
    saveOriginalViewport()
    local top = db.profile.viewport["top"]
    local bottom = db.profile.viewport["bottom"]
    local left = db.profile.viewport["left"]
    local right = db.profile.viewport["right"]
    setupViewport(top, bottom, left, right)
  else
    resetViewport()
  end
end

local function getViewportCoordinate(info)
  local key = info[#info]
  local val = db.profile.viewport[key]
  if not val then
    val = 0
  end
  local scaling = getViewpointScaling()
  val = _G.math.floor((val / scaling) + 0.5)
  return val
end

local function setViewportCoordinate(info, val)
  local key = info[#info]
  if not val then
    val = 0
  end
  local scaling = getViewpointScaling()
  val = _G.math.floor((val * scaling) + 0.5)
  db.profile.viewport[key] = val
  applyViewport()
end

local function setViewportToggle(info, val)
  db.profile.viewport.enable = val
  applyViewport()
end

local function getViewportToggle(info)
  return db.profile.viewport.enable
end


--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

SUB.defaults = {
  profile = {
    enable = false,
    top = 0,
    bottom = 0,
    left = 0,
    right = 0
  },
}

function SUB:RefreshDB()
  SUB:Print("Refreshing DB Profile")
  applyViewport()
end

function SUB:PLAYER_ENTERING_WORLD()
  SUB:Print("Refreshing DB Profile")
  applyViewport()
end

SUB:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Called by AceAddon.
function SUB:OnInitialize()
  --  self.db = MOD.db
  db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  db.RegisterCallback(self, "OnProfileReset", "RefreshDB")

  self:Print("SUBNAME: " .. SUBNAME)
  applyViewport()
end

-- Called by AceAddon.
function SUB:OnEnable()
  -- Nothing here yet.
end

-- Called by AceAddon.
function SUB:OnDisable()
  -- Nothing here yet.
end

function SUB:CreateOptions()
  local options = {
    header = {
      type = "header",
      name = L["options.viewport.header"],
      order = 1,
    },
    toggle = {
      type = "toggle",
      name = L["options.viewport.name"],
      width = "full",
      get = getViewportToggle,
      set = setViewportToggle,
      order = 2,
    },
    top = {
      type = "range",
      name = L["Top"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[2] / 2,
      step = 1,
      bigStep = 5,
      order = 34,
    },
    bottom = {
      type = "range",
      name = L["Bottom"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[2] / 2,
      step = 1,
      bigStep = 5,
      order = 36,
    },
    left = {
      type = "range",
      name = L["Left"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[1] / 2,
      step = 1,
      bigStep = 5,
      order = 38,
    },
    right = {
      type = "range",
      name = L["Right"],
      disabled = function()
        return not getViewportToggle()
      end,
      width = "full",
      get = getViewportCoordinate,
      set = setViewportCoordinate,
      min = 0,
      max = ({getCurrentScreenResolution()})[1] / 2,
      step = 1,
      bigStep = 5,
      order = 39,
    },
  }
  return options
end
