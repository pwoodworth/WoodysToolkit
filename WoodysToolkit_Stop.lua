--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME, MOD = ...
local SUBNAME = "Stop"
local SUB = MOD:NewModule(SUBNAME, "AceConsole-3.0", "AceEvent-3.0")
setfenv(1, SUB)

--------------------------------------------------------------------------------
-- Stop
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
  if db.profile.enabled then
    createStopButton()
    createStopMacro()
  end
end

local function getEnabledToggle(info)
  return db.profile.enabled
end

local function setEnabledToggle(info, val)
  db.profile.enabled = val
  applyStopButton()
end

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

SUB.defaults = {
  profile = {
    enabled = false,
  },
}

function SUB:ApplySettings()
  self:Printd("ApplySettings")
  applyStopButton()
end

function SUB:CreateOptions()
  local options = {
    header1 = {
      type = "header",
      name = L["Custom Escape Button"],
      order = 10,
    },
    enabled = {
      type = "toggle",
      name = L["Enable custom escape button"],
      width = "full",
      get = getEnabledToggle,
      set = setEnabledToggle,
      order = 11,
    },
  }
  return options
end
