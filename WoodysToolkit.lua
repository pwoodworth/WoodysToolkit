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
-- General
--------------------------------------------------------------------------------

local function applySettings()
  applyStopButton()
  applyIdpcFuncHack()
  for _, plugin in pairs(mPlugins) do
    if plugin["ApplySettings"] then
      plugin:ApplySettings()
    end
  end
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
