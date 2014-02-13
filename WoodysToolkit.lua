--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
WoodysToolkit._G = _G

_G["BINDING_HEADER_WoodysToolkit"] = "Woody's Toolkit"
setglobal("MACRO Cancel", "Stop casting, cancel targeting, and clear target.")

-- Set the environment of the current function to the global table MouselookHandler.
-- See: http://www.lua.org/pil/14.3.html
setfenv(1, WoodysToolkit)

local WoodysToolkit = _G.WoodysToolkit
local LibStub = _G.LibStub

local L = LibStub("AceLocale-3.0"):GetLocale("WoodysToolkit", true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

MODNAME = "WoodysToolkit"

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

databaseDefaults = {
  ["global"] = {
    ["version"] = nil,
  },
  ["profile"] = {
    ["escapeButtonToggle"] = false,
    ["idbpcHackToggle"] = false,
    ["viewportToggle"] = false,
  },
}

--------------------------------------------------------------------------------
-- IDPC Function Hack
--------------------------------------------------------------------------------

idbpcFunc = nil

local function applyIdpcFuncHack()
  if db.profile.idbpcHackToggle then
    if not idbpcFunc then
      idbpcFunc = _G.C_StorePublic.IsDisabledByParentalControls
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

local function createStopButton()
    local ESCAPE_BUTTON_NAME = "WoodysStopButton"
    local b = _G[ESCAPE_BUTTON_NAME] or _G.CreateFrame("Button", ESCAPE_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
    b:SetAttribute("type", "stop")
end

local function createClearMacro()
    local body = "/stopcasting\n/cleartarget\n/click WoodysStopButton"
    local idx = GetMacroIndexByName("Cancel")
    if (idx == 0) then
        CreateMacro("Cancel", "INV_Feather_02", body, nil)
    else
        EditMacro(idx, "Cancel", nil, body, 1, 1)
    end
end

local function applyStopButton()
  if db.profile.escapeButtonToggle then
    createStopButton()
  end
end

local function setEscapeButtonToggle(info, val)
  db.profile.escapeButtonToggle = val
  applyStopButton()
end

local function getEscapeButtonToggle(info)
  return db.profile.escapeButtonToggle
end

--------------------------------------------------------------------------------
-- Viewport
--------------------------------------------------------------------------------

ViewportOverlay = nil

local function setupViewport()
  if not ViewportOverlay then
    ViewportOverlay = WorldFrame:CreateTexture(nil, "BACKGROUND")
    ViewportOverlay:SetTexture(0, 0, 0, 1)
    ViewportOverlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, 1)
    ViewportOverlay:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1, -1)
  end

  -- Configuration
  local top = 0 -- Pixels from top
  local bottom = 200 -- Pixels from bottom
  local left = 0 -- Pixels from left
  local right = 0 -- Pixels from right

  local curResString = ({GetScreenResolutions()})[GetCurrentResolution()]
  print('The current screen resolution is ' .. curResString)
  for token in string.gmatch(curResString, "[^x]+") do
    print(token)
  end

  for k, v in string.gmatch(curResString, "(%w+)x(%w+)") do
    print("w="..k.." h="..v)
  end

  -- Your current Y resolution (e.g. 1920x1080, Y = 1080)
  local currentYResolution = 1200
  -- End configuration

  local scaling = 768 / currentYResolution

  WorldFrame:SetPoint("TOPLEFT", (left * scaling), -(top * scaling))
  WorldFrame:SetPoint("BOTTOMRIGHT", -(right * scaling), (bottom * scaling))
end

local function applyViewport()
  if db.profile.viewportToggle then
    setupViewport()
  end
end

local function setViewportToggle(info, val)
  db.profile.viewportToggle = val
  applyViewport()
end

local function getViewportToggle(info)
  return db.profile.viewportToggle
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

--[[
local function setOverrideBinding(info, val)
  local bindingname = info[#info]
  if val == "false" then
    val = nil
  end
  db.profile.mouseOverrideBindings[bindingname] = val
  applyUseOverrideBindings()
end

local function getOverrideBinding(info)
  local bindingname = info[#info]
  local val = db.profile.mouseOverrideBindings[bindingname]
  if not val then
    val = "false"
  end
  return val
end
--]]

local function applySettings()
  applyStopButton()
  applyIdpcFuncHack()
  applyViewport()
end

local options = {
  type = "group",
  name = L["options.name"],
  handler = WoodysToolkit,
  childGroups = "tree",
  args = {
    escapeButtonHeader = {
      type = "header",
      name = L["options.escapeButton.header"],
      order = 0,
    },
    escapeButtonDescription = {
      type = "description",
      name = L["options.escapeButton.description"],
      fontSize = "medium",
      order = 1,
    },
    escapeButtonToggle = {
      type = "toggle",
      name = L["options.escapeButton.name"],
      width = "full",
      set = setEscapeButtonToggle,
      get = getEscapeButtonToggle,
      order = 2,
    },
    idbpcHackHeader = {
      type = "header",
      name = L["options.idbpcHack.header"],
      order = 3,
    },
    idbpcHackDescription = {
      type = "description",
      name = L["options.idbpcHack.description"],
      fontSize = "medium",
      order = 4,
    },
    idbpcHackToggle = {
      type = "toggle",
      name = L["options.idbpcHack.name"],
      width = "full",
      set = setIdbpcHackToggle,
      get = getIdbpcHackToggle,
      order = 5,
    },
    idbpcHackHeader = {
      type = "header",
      name = L["options.viewport.header"],
      order = 30,
    },
    idbpcHackDescription = {
      type = "description",
      name = L["options.viewport.description"],
      fontSize = "medium",
      order = 31,
    },
    viewportToggle = {
      type = "toggle",
      name = L["options.viewport.name"],
      width = "full",
      get = getViewportToggle,
      set = setViewportToggle,
      order = 32,
    },
    reloadButton = {
      type = "execute",
      name = L["options.reloadui.name"],
      width = "half",
      func = function()
        _G.ReloadUI()
      end,
      order = 90,
    },
  },
}

function WoodysToolkit:RefreshDB()
  WoodysToolkit:Print("Refreshing DB Profile")
  applySettings()
end

--------------------------------------------------------------------------------
-- </ Event Handlers > ------------------------------------------
--------------------------------------------------------------------------------

function WoodysToolkit:ADDON_LOADED()
  --_G.print("Woody's Toolkit loaded!")
  self:UnregisterEvent("ADDON_LOADED")
end

function WoodysToolkit:PLAYER_ENTERING_WORLD()
  applySettings()
end

function WoodysToolkit:PLAYER_LOGIN()
  -- Nothing here yet.
end

WoodysToolkit:RegisterEvent("ADDON_LOADED")
WoodysToolkit:RegisterEvent("PLAYER_ENTERING_WORLD")
WoodysToolkit:RegisterEvent("PLAYER_LOGIN")

--------------------------------------------------------------------------------
-- </ in-game configuration UI code > ------------------------------------------
--------------------------------------------------------------------------------

-- See: wowace.com/addons/ace3/pages/getting-started/#w-standard-methods
function WoodysToolkit:OnInitialize()
  -- The ".toc" need say "## SavedVariables: WoodysToolkitDB".
  self.db = LibStub("AceDB-3.0"):New(MODNAME .. "DB", databaseDefaults, true)

  local currentVersion = _G.GetAddOnMetadata(MODNAME, "Version")
  self.db.global.version = currentVersion

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:RefreshDB()

  -- See: wowace.com/addons/ace3/pages/getting-started/#w-registering-the-options
  AceConfig:RegisterOptionsTable(MODNAME, options)

  -- Register the Ac3 profile options table
  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_Profiles", profiles)

  local configFrame = AceConfigDialog:AddToBlizOptions(MODNAME, "WoodysToolkit")
  AceConfigDialog:AddToBlizOptions(MODNAME .. "_Profiles", profiles.name, "WoodysToolkit")
  configFrame.default = function()
    self.db:ResetProfile()
  end

  local function toggleOptionsUI()
    if not _G.InCombatLockdown() then
      _G.InterfaceOptionsFrame_OpenToCategory(configFrame)
      -- Called twice to workaround UI bug
      _G.InterfaceOptionsFrame_OpenToCategory(configFrame)
    end
  end
  self:RegisterChatCommand("woodystoolkit", toggleOptionsUI)
  self:RegisterChatCommand("wtk", toggleOptionsUI)

  applySettings()
end

-- Called by AceAddon.
function WoodysToolkit:OnEnable()
  -- Nothing here yet.
end

-- Called by AceAddon.
function WoodysToolkit:OnDisable()
  -- Nothing here yet.
end

