_G["BINDING_HEADER_WOODYSTOOLKIT"] = "Woody's Toolkit"

--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

WoodysToolkit = WoodysToolkit or LibStub("AceAddon-3.0"):NewAddon("WoodysToolkit", "AceConsole-3.0", "AceEvent-3.0")
local _G = getfenv(0)
WoodysToolkit._G = WoodysToolkit._G or _G
setfenv(1, WoodysToolkit)

MODNAME = "WoodysToolkit"

local WoodysToolkit = _G.WoodysToolkit
local MOD = WoodysToolkit
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
local type = _G.type

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

mPlugins = mPlugins or {}

mConfigFrame = nil

local function createDatabaseDefaults()
  local databaseDefaults = {
    ["global"] = {
      ["version"] = nil,
      Minimap = { hide = false, minimapPos = 180, radius = 80, }, -- saved DBIcon minimap settings
    },
    ["profile"] = {
      ["stopButtonToggle"] = false,
      ["idbpcHackToggle"] = false,
      autoDuelDecline = true,
    },
  }

  for k, v in pairs(mPlugins) do
    if v.defaults then
      databaseDefaults["global"][k] = v.defaults.global
      databaseDefaults["profile"][k] = v.defaults.profile
    end
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

local function toggleOptions()
    if not _G.InCombatLockdown() then
      _G.InterfaceOptionsFrame_OpenToCategory(mConfigFrame)
      -- Called twice to workaround UI bug
      _G.InterfaceOptionsFrame_OpenToCategory(mConfigFrame)
    end
end

function MOD:ToggleOptions()
  toggleOptions()
end

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

function MOD:CreateOptions()
  local options = {
    type = "group",
    name = L["options.name"],
    handler = MOD,
    childGroups = "tree",
    args = {
      config = {
        type = "execute",
        name = L["options.config.name"],
        guiHidden = true,
        func = toggleOptions,
        order = 1,
      },
      general = {
        type = "group",
        name = "General",
        order = 2,
        args = {
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
      },
    },
  }
  return options
end

local function printTable(t)
  for k, v in pairs(t) do
    print("  key: " .. k .. " ; type: " .. type(v))
  end
end

function MOD:PopulateOptions()
  local options = {}
  copyTable(MOD:CreateOptions(), options)

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
      options.args[k] = pluginOptions
      copyTable(v:CreateOptions(), pluginOptions.args)
--      AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_" .. pluginOptions.name, pluginOptions)
--      AceConfigDialog:AddToBlizOptions(MODNAME .. "_" .. pluginOptions.name, pluginOptions.name, MODNAME)
  end


  AceConfig:RegisterOptionsTable(MODNAME, options)
  mConfigFrame = mConfigFrame or AceConfigDialog:AddToBlizOptions(MODNAME, "WoodysToolkit")
  mConfigFrame.default = function(...)
  --    self.db:ResetProfile()
    for i=1,select("#", ...) do
      local x = select(i, ...)
      print("arg" .. i .. ": " .. type(x))
      printTable(x)
    end
  end


  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_Profiles", profiles)
  AceConfigDialog:AddToBlizOptions(MODNAME .. "_Profiles", profiles.name, "WoodysToolkit")

  return options
end

function MOD:RefreshDB()
  MOD:Print("Refreshing DB Profile")
  applySettings()
end

--------------------------------------------------------------------------------
-- </ Event Handlers > ------------------------------------------
--------------------------------------------------------------------------------

function MOD:ADDON_LOADED()
  self:UnregisterEvent("ADDON_LOADED")
end

function MOD:PLAYER_ENTERING_WORLD()
  applySettings()
end

function MOD:PLAYER_LOGIN()
  -- Nothing here yet.
end

function MOD:DUEL_REQUESTED(event, name)
  if self.db.profile.autoDuelDecline then
    HideUIPanel(StaticPopup1);
    CancelDuel();
  end
end

function MOD:MERCHANT_SHOW()
  for _, plugin in pairs(mPlugins) do
    if plugin["MERCHANT_SHOW"] then
      plugin:MERCHANT_SHOW()
    end
  end
end

MOD:RegisterEvent("ADDON_LOADED")
MOD:RegisterEvent("PLAYER_ENTERING_WORLD")
MOD:RegisterEvent("PLAYER_LOGIN")
MOD:RegisterEvent("DUEL_REQUESTED")

--------------------------------------------------------------------------------
-- </ in-game configuration UI code > ------------------------------------------
--------------------------------------------------------------------------------

function MOD:OptionsPanel()
  MOD:ToggleOptions()
end

-- Tie into LibDataBroker
function MOD:InitializeLDB()
  local LDB = LibStub("LibDataBroker-1.1", true)
  if not LDB then return end
  MOD.ldb = LDB:NewDataObject("WoodysToolkit", {
    type = "launcher",
    text = "Woody's Toolkit",
    icon = "Interface\\Icons\\Trade_Engineering",
    OnClick = function(_, msg)
      MOD:OptionsPanel()
--      if msg == "RightButton" then
--        if IsShiftKeyDown() then
--          MOD.db.profile.hideBlizz = not MOD.db.profile.hideBlizz
--          MOD.db.profile.hideConsolidated = MOD.db.profile.hideBlizz
--        else
--          MOD:ToggleBarGroupLocks()
--        end
--      elseif msg == "LeftButton" then
--        if IsShiftKeyDown() then
--          MOD.db.profile.enabled = not MOD.db.profile.enabled
--        else
--          MOD:OptionsPanel()
--        end
--      end
--      doUpdate = true
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine(L["WTK"])
      tooltip:AddLine(L["WTK left click"])
--      tooltip:AddLine(L["WTK right click"])
--      tooltip:AddLine(L["WTK shift left click"])
--      tooltip:AddLine(L["WTK shift right click"])
    end,
  })
  MOD.ldbi = LibStub("LibDBIcon-1.0", true)
  if MOD.ldbi then MOD.ldbi:Register("WoodysToolkit", MOD.ldb, MOD.db.global.Minimap) end
end


-- See: wowace.com/addons/ace3/pages/getting-started/#w-standard-methods
function MOD:OnInitialize()
  -- The ".toc" need say "## SavedVariables: WoodysToolkitDB".
  self.db = LibStub("AceDB-3.0"):New(MODNAME .. "DB", createDatabaseDefaults(), true)

  local currentVersion = _G.GetAddOnMetadata(MODNAME, "Version")
  self.db.global.version = currentVersion

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:RefreshDB()

  for _, plugin in pairs(mPlugins) do
    if plugin["OnInitialize"] then
      plugin:OnInitialize()
    end
  end

  local options = self:PopulateOptions()
--  AceConfig:RegisterOptionsTable(MODNAME, options)
--  mConfigFrame = mConfigFrame or AceConfigDialog:AddToBlizOptions(MODNAME, "WoodysToolkit")
--  mConfigFrame.default = function()
--    self.db:ResetProfile()
--  end
--
--  local orderidx = 100
--  for k, v in pairs(mPlugins) do
--    orderidx = orderidx + 10
--    local pluginOptions = {
--      order = orderidx,
--      type = "group",
--      name = v["name"] or k,
--      args = {
--      }
--    }
--    copyTable(v:CreateOptions(), pluginOptions.args)
--    AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_" .. pluginOptions.name, pluginOptions)
--    AceConfigDialog:AddToBlizOptions(MODNAME .. "_" .. pluginOptions.name, pluginOptions.name, MODNAME)
--  end
--
--  local profiles = AceDBOptions:GetOptionsTable(self.db)
--  AceConfigRegistry:RegisterOptionsTable(MODNAME .. "_Profiles", profiles)
--  AceConfigDialog:AddToBlizOptions(MODNAME .. "_Profiles", profiles.name, "WoodysToolkit")

  LibStub("AceConfigCmd-3.0").CreateChatCommand(MOD, "woodystoolkit", MODNAME)
  LibStub("AceConfigCmd-3.0").CreateChatCommand(MOD, "wtk", MODNAME)

  self:InitializeLDB()

  applySettings()
end

-- Called by AceAddon.
function MOD:OnEnable()
  self:RegisterEvent("MERCHANT_SHOW")
end

-- Called by AceAddon.
function MOD:OnDisable()
  -- Nothing here yet.
end
