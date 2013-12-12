--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
WoodysToolkit._G = _G

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

idbpcFunc = nil

databaseDefaults = {
  ["global"] = {
    ["version"] = nil,
  },
  ["profile"] = {
    ["idbpcHackToggle"] = false,
    ["escapeButtonToggle"] = false,
  },
}

local function applySettings()
  local ESCAPE_BUTTON_NAME = "WoodysEscapeButton"
  if db.profile.escapeButtonToggle then
    local b = _G[ESCAPE_BUTTON_NAME] or CreateFrame("Button", ESCAPE_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
    b:SetAttribute("type", "stop")
  end
  if db.profile.idbpcHackToggle then
    if not idbpcFunc then
      idbpcFunc = _G.C_StorePublic.IsDisabledByParentalControls
      _G.C_StorePublic.IsDisabledByParentalControls = function () return false end
    end
  end
end

local function setEscapeButtonToggle(info, val)
  db.profile.escapeButtonToggle = val
  applySettings()
end

local function getEscapeButtonToggle(info)
  return db.profile.escapeButtonToggle
end

local function setIdbpcHackToggle(info, val)
  db.profile.idbpcHackToggle = val
  applySettings()
end

local function getIdbpcHackToggle(info)
  return db.profile.idbpcHackToggle
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
    reloadButton = {
      type = "execute",
      name = L["options.reloadui.name"],
      width = "half",
      func = function()
        _G.ReloadUI()
      end,
      order = 6,
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

