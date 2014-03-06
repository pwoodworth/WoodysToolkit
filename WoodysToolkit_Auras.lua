--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME, MOD = ...
local SUBNAME = "Auras"
local SUB = MOD:NewModule(SUBNAME, "AceConsole-3.0", "AceEvent-3.0")
setfenv(1, SUB)

--------------------------------------------------------------------------------
-- Auras
--------------------------------------------------------------------------------

--[[
COMBAT_LOG_EVENT_UNFILTERED, PLAYER_ENTERING_WORLD, ACTIONBAR_UPDATE_COOLDOWN, SPELL_UPDATE_COOLDOWN
--]]

that = function(event, _, logevent, _, ...)
  local reverse = false
  local trigger = false
  local now = GetTime()
  local start, _, enable = GetInventoryItemCooldown("player", 10)
  local castart, caduration, caenabled = GetSpellCooldown("Celestial Alignment")
  local caleft = 0
  if enable and start and castart and start == 0 and castart > 0 then
    caleft = ((castart + caduration) - now)
    if (caleft > 60) then
      trigger = true
    end
  end
  if trigger ~= reverse then
    -- local prefix = trigger and "TRIGGER" or "UNTRIGGER"
    -- print(prefix.." caleft: "..caleft)
    return true
  end
  return false
end

-- Tempus Repit  -- Sinister Primal Diamond

local function applyAuras()
  if db.profile.enabled then
    -- nothing
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
  applyAuras()
end

function SUB:CreateOptions()
  local options = {
    header1 = {
      type = "header",
      name = L["Woody's Aura Settings"],
      order = 10,
    },
    enabled = {
      type = "toggle",
      name = L["Enable aura functions"],
      width = "full",
      get = getEnabledToggle,
      set = setEnabledToggle,
      order = 11,
    },
  }
  return options
end


