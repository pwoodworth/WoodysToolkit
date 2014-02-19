--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
WoodysToolkit._G = WoodysToolkit._G or _G
setfenv(1, WoodysToolkit)

MODNAME = "WoodysToolkit"

local WoodysToolkit = _G.WoodysToolkit
local LibStub = _G.LibStub

local L = LibStub("AceLocale-3.0"):GetLocale("WoodysToolkit", true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local MyAddOn = LibStub("AceAddon-3.0"):GetAddon(MODNAME)

-- upvalues
local print = print or _G.print
local string = string or _G.string
local floor = _G.floor
local mod = _G.mod
local pairs = _G.pairs
local wipe = _G.wipe
local select = _G.select

--local string_find = _G.string.find
--local DeleteCursorItem = _G.DeleteCursorItem
--local GetContainerItemInfo = _G.GetContainerItemInfo
--local GetItemInfo = _G.GetItemInfo
--local PickupContainerItem = _G.PickupContainerItem
--local PickupMerchantItem = _G.PickupMerchantItem
--local IsAddOnLoaded = _G.IsAddOnLoaded
--local COPPER_PER_SILVER = _G.COPPER_PER_SILVER
--local SILVER_PER_GOLD = _G.SILVER_PER_GOLD



--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

_G["BINDING_HEADER_WOODYSTOOLKIT"] = "Woody's Toolkit"

mPlugins = mPlugins or {}

mConfigFrame = nil

local function createDatabaseDefaults()
  local databaseDefaults = {
    ["global"] = {
      ["version"] = nil,
    },
    ["profile"] = {
      ["stopButtonToggle"] = false,
      ["idbpcHackToggle"] = false,
      ["viewport"] = {
        enable = false,
        top = 0,
        bottom = 0,
        left = 0,
        right = 0
      },
    },
  }

  for k, v in pairs(mPlugins) do
    databaseDefaults["profile"][k] = v.defaults
  end

  return databaseDefaults
end

--------------------------------------------------------------------------------
-- IDPC Function Hack
--------------------------------------------------------------------------------

mIdbpcFunc = nil

local function applyIdpcFuncHack()
  if db.profile.idbpcHackToggle then
    if not mIdbpcFunc then
      mIdbpcFunc = _G.C_StorePublic.IsDisabledByParentalControls
      _G.C_StorePublic.IsDisabledByParentalControls = function () return false end
    end
  end
end

local function setIdbpcHackToggle(info, val)
  db.profile.idbpcHackToggle = val
  applyIdpcFuncHack()
end

local function getIdbpcHackToggle(info)
  return db.profile.idbpcHackToggle
end

--------------------------------------------------------------------------------
-- Stop Button
--------------------------------------------------------------------------------

local STOP_BUTTON_NAME = "WoodysStopButton"
local STOP_MACRO_NAME = "wtkstop"

_G.setglobal("MACRO "..STOP_MACRO_NAME, "Stop casting, cancel targeting, and clear target.")

local function createStopButton()
    local b = _G[STOP_BUTTON_NAME] or _G.CreateFrame("Button", STOP_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
    b:SetAttribute("type", "stop")
end

local function createStopMacro()
    local body = "/stopcasting\n/cleartarget\n/click "..STOP_BUTTON_NAME
    local idx = _G.GetMacroIndexByName(STOP_MACRO_NAME)
    if (idx == 0) then
        _G.CreateMacro(STOP_MACRO_NAME, "INV_Feather_02", body, nil)
    else
        _G.EditMacro(idx, STOP_MACRO_NAME, nil, body, 1, 1)
    end
end

local function applyStopButton()
  if db.profile.stopButtonToggle then
    createStopButton()
    createStopMacro()
  end
end

local function setStopButtonToggle(info, val)
  db.profile.stopButtonToggle = val
  applyStopButton()
end

local function getStopButtonToggle(info)
  return db.profile.stopButtonToggle
end

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
-- General
--------------------------------------------------------------------------------

local function applySettings()
  applyStopButton()
  applyIdpcFuncHack()
  applyViewport()
end

local function copyTable(src, dst)
  local dst = dst or {}
  for k,v in pairs(src) do
    dst[k] = v
  end
  return dst
end

function MyAddOn:CreateOptions()
  local options = {
    type = "group",
    name = L["options.name"],
    handler = WoodysToolkit,
    childGroups = "tree",
    args = {
      config = {
        type = "execute",
        name = L["options.config.name"],
        guiHidden = true,
        func = function()
            if not _G.InCombatLockdown() then
              _G.InterfaceOptionsFrame_OpenToCategory(mConfigFrame)
              -- Called twice to workaround UI bug
              _G.InterfaceOptionsFrame_OpenToCategory(mConfigFrame)
            end
          end,
        order = 1,
      },
      stopButtonHeader = {
        type = "header",
        name = L["options.escapeButton.header"],
        order = 10,
      },
      stopButton = {
        type = "toggle",
        name = L["options.escapeButton.name"],
        width = "full",
        set = setStopButtonToggle,
        get = getStopButtonToggle,
        order = 11,
      },
      viewport = {
        type = "group",
        name = L["Viewport"],
        guiInline = true,
        order = 20,
        args = {
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
        },
      },
      miscHeader = {
        type = "header",
        name = L["options.misc.header.name"],
        order = 90,
      },
      idbpcHack = {
        type = "toggle",
        name = L["options.idbpcHack.name"],
        width = "full",
        set = setIdbpcHackToggle,
        get = getIdbpcHackToggle,
        order = 91,
      },
      reloadButton = {
        type = "execute",
        name = L["options.reloadui.name"],
        cmdHidden = true,
        width = nil,
        func = function()
          _G.ReloadUI()
        end,
        order = 92,
      },
    },
  }
  return options
end

function MyAddOn:PopulateOptions()
  local options = {}
  copyTable(MyAddOn:CreateOptions(), options)
  return options
end

function WoodysToolkit:RefreshDB()
  WoodysToolkit:Print("Refreshing DB Profile")
  applySettings()
end

--------------------------------------------------------------------------------
-- </ Event Handlers > ------------------------------------------
--------------------------------------------------------------------------------

function WoodysToolkit:ADDON_LOADED()
  self:UnregisterEvent("ADDON_LOADED")
end

function WoodysToolkit:PLAYER_ENTERING_WORLD()
  applySettings()
end

function WoodysToolkit:PLAYER_LOGIN()
  -- Nothing here yet.
end

function WoodysToolkit:MERCHANT_SHOW()
  for _, plugin in pairs(mPlugins) do
    if plugin["MERCHANT_SHOW"] then
      plugin:MERCHANT_SHOW()
    end
  end
end

WoodysToolkit:RegisterEvent("ADDON_LOADED")
WoodysToolkit:RegisterEvent("PLAYER_ENTERING_WORLD")
WoodysToolkit:RegisterEvent("PLAYER_LOGIN")
--WoodysToolkit:RegisterEvent("MERCHANT_SHOW")

--------------------------------------------------------------------------------
-- </ in-game configuration UI code > ------------------------------------------
--------------------------------------------------------------------------------

-- See: wowace.com/addons/ace3/pages/getting-started/#w-standard-methods
function WoodysToolkit:OnInitialize()
  -- The ".toc" need say "## SavedVariables: WoodysToolkitDB".
  self.db = LibStub("AceDB-3.0"):New(MODNAME .. "DB", createDatabaseDefaults(), true)

  local currentVersion = _G.GetAddOnMetadata(MODNAME, "Version")
  self.db.global.version = currentVersion

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:RefreshDB()

  -- See: wowace.com/addons/ace3/pages/getting-started/#w-registering-the-options
  local options = self:PopulateOptions()
  AceConfig:RegisterOptionsTable(MODNAME, options)

  -- Register the Ace3 profile options table
  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_Profiles", profiles)

  mConfigFrame = mConfigFrame or AceConfigDialog:AddToBlizOptions(MODNAME, "WoodysToolkit")
  AceConfigDialog:AddToBlizOptions(MODNAME .. "_Profiles", profiles.name, "WoodysToolkit")
  mConfigFrame.default = function()
    self.db:ResetProfile()
  end

  print("profiles.name: "..profiles.name)
  local orderidx = 100
  for k, v in pairs(mPlugins) do
    orderidx = orderidx + 10
    local pluginOptions = {
      order = orderidx,
      type = "group",
      name = v["name"] or k,
      args = {
      }
    }
    copyTable(v:CreateOptions(), pluginOptions.args)
    AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_" .. pluginOptions.name, pluginOptions)
    AceConfigDialog:AddToBlizOptions(MODNAME .. "_" .. pluginOptions.name, pluginOptions.name, MODNAME)
  end


  LibStub("AceConfigCmd-3.0").CreateChatCommand(WoodysToolkit, "woodystoolkit", MODNAME)
  LibStub("AceConfigCmd-3.0").CreateChatCommand(WoodysToolkit, "wtk", MODNAME)

  applySettings()
end

-- Called by AceAddon.
function WoodysToolkit:OnEnable()
  self:RegisterEvent("MERCHANT_SHOW")
  self.total = 0
end

-- Called by AceAddon.
function WoodysToolkit:OnDisable()
  -- Nothing here yet.
end
