--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME, MOD = ...
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
      ["stopbutton"] = false,
    },
  }
  return databaseDefaults
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
  if db.profile.stopbutton then
    createStopButton()
    createStopMacro()
  end
end

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------

local function applySettings()
  applyStopButton()
end

function MOD:ApplySettings()
  applySettings()
end

function MOD:GetToggleOption(info)
  local key = info[#info]
  local val = db.profile[key]
  return val
end

function MOD:SetToggleOption(info, val)
  local key = info[#info]
  db.profile[key] = val
  self:Printd("option: " .. key .. " = " .. tostring(db.profile[key]))
  self:ApplySettings()
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
      stopbutton = {
        type = "toggle",
        name = L["options.escapeButton.name"],
        width = "full",
        get = "GetToggleOption",
        set = "SetToggleOption",
        order = 11,
      },
      miscHeader = {
        type = "header",
        name = L["options.misc.header.name"],
        order = 90,
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

