--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME = ...
local _G = getfenv(0)

local function pdebug(...)
  print("DEBUG: ", ...)
end

local function psdebug(self, ...)
  self:Print("DEBUG: ", ...)
end

local upvalues = setmetatable({}, { __index = _G })
upvalues = setmetatable({
  printd = pdebug,
  Printd = psdebug,
}, { __index = upvalues })
_G[MODNAME] = _G[MODNAME] or LibStub("AceAddon-3.0"):NewAddon(upvalues, MODNAME, "AceConsole-3.0", "AceEvent-3.0")
local MOD = LibStub("AceAddon-3.0"):GetAddon(MODNAME)
setfenv(1, MOD)
local LibStub = _G.LibStub
MOD.L = MOD.L or LibStub("AceLocale-3.0"):GetLocale(MODNAME, true)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceTab = LibStub("AceTab-3.0")

_G["BINDING_HEADER_WOODYSTOOLKIT"] = "Woody's Toolkit"

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

local function invokeModules(funcname, ...)
  for name, module in MOD:IterateModules() do
    if type(module[funcname]) == "function" then
      module[funcname](module, ...)
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

local function printTable(t)
  local count = 0
  for k, v in pairsByKeys(t) do
    count = count + 1
    printd("  key: " .. _G.tostring(k) .. " ; type: " .. type(v))
  end
  printd("key count: " .. count)
end

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

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

  for name, module in MOD:IterateModules() do
    if module.defaults then
      databaseDefaults["global"][name:lower()] = module.defaults.global
      databaseDefaults["profile"][name:lower()] = module.defaults.profile
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
      -- Called twice to workaround UI bug
      _G.InterfaceOptionsFrame_OpenToCategory(MODNAME)
      _G.InterfaceOptionsFrame_OpenToCategory(MODNAME)
    end
end

function MOD:ToggleOptions()
  toggleOptions()
end

local function applySettings()
  applyStopButton()
  applyIdpcFuncHack()
--  invokeModules("ApplySettings")
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

function MOD:PopulateOptions()
  local options = {}
  copyTable(MOD:CreateOptions(), options)

  local orderidx = 100

  for name, module in MOD:IterateModules() do
    orderidx = orderidx + 10
    local pluginOptions = {
      order = orderidx,
      type = "group",
      name = name,
      args = {
      }
    }
    options.args[name:lower()] = pluginOptions
    copyTable(module:CreateOptions(), pluginOptions.args)
  end

  AceConfig:RegisterOptionsTable(MODNAME, options)
  MOD.mConfigFrame = MOD.mConfigFrame or AceConfigDialog:AddToBlizOptions(MODNAME, "WoodysToolkit", nil, "general")
  MOD.mConfigFrame.default = function(...)
    self.db:ResetProfile()
  end

  for name, module in MOD:IterateModules() do
    AceConfigDialog:AddToBlizOptions(MODNAME, name, MODNAME, name:lower())
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
  MOD.ldb = LDB:NewDataObject(MODNAME, {
    type = "launcher",
    text = "Woody's Toolkit",
    icon = "Interface\\Icons\\Trade_Engineering",
    OnClick = function(_, msg)
      if msg == "RightButton" then
        if _G.IsShiftKeyDown() then
          MOD:OptionsPanel()
        else
          printTable(MOD)
        end
      elseif msg == "LeftButton" then
        if _G.IsShiftKeyDown() then
          MOD:OptionsPanel()
        else
          MOD:OptionsPanel()
        end
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine(L["WTK"])
      tooltip:AddLine(L["WTK left click"])
      tooltip:AddLine(L["WTK right click"])
      tooltip:AddLine(L["WTK shift left click"])
      tooltip:AddLine(L["WTK shift right click"])
    end,
  })
  MOD.ldbi = LibStub("LibDBIcon-1.0", true)
  if MOD.ldbi then MOD.ldbi:Register("WoodysToolkit", MOD.ldb, MOD.db.global.Minimap) end
end


-- See: wowace.com/addons/ace3/pages/getting-started/#w-standard-methods
function MOD:OnInitialize()
  self:Printd("OnInitialize")
  -- The ".toc" need say "## SavedVariables: WoodysToolkitDB".
  self.db = AceDB:New(MODNAME .. "DB", createDatabaseDefaults(), true)

  local currentVersion = _G.GetAddOnMetadata(MODNAME, "Version")
  self.db.global.version = currentVersion

  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
  self:RefreshDB()

  local options = self:PopulateOptions()

  AceConfigCmd.CreateChatCommand(MOD, "woodystoolkit", MODNAME)
  AceConfigCmd.CreateChatCommand(MOD, "wtk", MODNAME)

  self:InitializeLDB()

  applySettings()
end

-- Called by AceAddon.
function MOD:OnEnable()
  self:Printd("OnEnable")
end

-- Called by AceAddon.
function MOD:OnDisable()
  self:Printd("OnDisable")
end
