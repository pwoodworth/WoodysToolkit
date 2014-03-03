--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME = ...
local MOD = LibStub("AceAddon-3.0"):GetAddon(MODNAME)
--local SUBNAME = "Viewport"
--local SUB = MOD:NewModule(SUBNAME, "AceConsole-3.0", "AceEvent-3.0")
setfenv(1, MOD)

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

function MOD:CreateDatabaseDefaults()
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
-- Decline Duel
--------------------------------------------------------------------------------

function MOD:DUEL_REQUESTED(event, name)
  if self.db.profile.autoDuelDecline then
    HideUIPanel(StaticPopup1);
    CancelDuel();
  end
end

MOD:RegisterEvent("DUEL_REQUESTED")

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

function MOD:ApplySettings()
  applyStopButton()
  applyIdpcFuncHack()
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
        func = function() MOD:ToggleOptions() end,
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

