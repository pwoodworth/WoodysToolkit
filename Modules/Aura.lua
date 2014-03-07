--------------------------------------------------------------------------------
-- AddOn Initialization
--------------------------------------------------------------------------------

local MODNAME, MOD = ...
local SUBNAME = "Aura"
local SUB = MOD:NewModule(SUBNAME, "AceConsole-3.0", "AceEvent-3.0")
setfenv(1, SUB)

--------------------------------------------------------------------------------
-- Auras
--------------------------------------------------------------------------------

local function isAvailableWithin(spellname, seconds)
  local castart, caduration, caenabled = GetSpellCooldown(spellname)
  if castart and castart > 0 then
    local now = GetTime()
    local caleft = ((castart + caduration) - now)
    if (caleft > seconds) then
      return false
    end
  end
  return true
end


--[[
COMBAT_LOG_EVENT_UNFILTERED, PLAYER_ENTERING_WORLD, ACTIONBAR_UPDATE_COOLDOWN, SPELL_UPDATE_COOLDOWN
--]]

_G.WoodysAuraTool = {
  synapse = {
    trigger = function(reverse, ...)
      local trigger = false
      local start, _, enable = GetInventoryItemCooldown("player", 10)
      if enable and start and start == 0 then
        trigger = not isAvailableWithin("Celestial Alignment", 60)
      end
      if trigger ~= reverse then
        return true
      end
      return false
    end,
    trigger2 = function(reverse, event, _, logevent, _, ...)
    --    local reverse = false
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
    end,
  }
}

--[[ SNAPSHOT LOGIC : Icon ]]--
local snapshotLogic = {
  Trigger = {
    Type = [[Custom]],
    EventType = [[Event]],
    Events = [[COMBAT_LOG_EVENT_UNFILTERED]],
    Hide = [[Timed]],
    CustomTrigger = function(...)
      local _, _, event, _, source, _, _, _, destination, _, _, _, spell, _, _, _, _, _, _, _, _, _ = ...
      if (source == UnitGUID("player") and destination == UnitGUID("target") and event == "SPELL_CAST_SUCCESS") then
        if (spell == 8921) then
          Moon_sDamage = (1841 + 0.24 * SPArc) * DamageMultiplierArc
          Sun_sDamage = (UnitBuff("player", "Celestial Alignment") and ((1841 + 0.24 * SPNat) * DamageMultiplierNat)) or Sun_sDamage
        elseif (spell == 93402) then
          Sun_sDamage = (1841 + 0.24 * SPNat) * DamageMultiplierNat
          Moon_sDamage = (UnitBuff("player", "Celestial Alignment") and ((1841 + 0.24 * SPArc) * DamageMultiplierArc)) or Moon_sDamage
        end
      end
    end
  },
}
--[[ STAT LOGIC : Text ]]--
--[[
  display text
  update text on every frame
  trigger: Moonkin Form, Incarnation: Chosen of Elune
--]]
local statLogic = {
  Display = {
    DisplayText = [[%c]],
    UpdateCustomTextOn = [[EveryFrame]],
    CustomFunction = function()
      SPNat, SPArc = GetSpellBonusDamage(4), GetSpellBonusDamage(7)
      local CritNat, CritArc = (1 + GetSpellCritChance(4) / 100), (1 + GetSpellCritChance(7) / 100)
      local Mastery = GetMasteryEffect() / 100
      local Ticks = ceil(7 * UnitSpellHaste("player") / 100) / 7 + 1
      local EclipseArc = (UnitBuff("player", "Eclipse (Lunar)") and (1.15 + Mastery)) or 1
      local EclipseNat = (UnitBuff("player", "Eclipse (Solar)") and (1.15 + Mastery)) or 1
      local CelestialAlignment = (UnitBuff("player", "Celestial Alignment") and 1.15) or 1
      local Form = (UnitBuff("player", "Incarnation: Chosen of Elune") and 1.4) or 1.15
      local Form = (UnitBuff("player", "Moonkin Form") and 1.4) or 1.15
      DamageMultiplierArc = EclipseArc * CelestialAlignment * Form * Ticks * CritArc
      DamageMultiplierNat = EclipseNat * CelestialAlignment * Form * Ticks * CritNat
      return ''
    end
  },
  Trigger = {
    Type = [[Aura]],
    Auras = [[Moonkin Form, Incarnation: Chosen of Elune]],
  },
}


--[[ SUNFIRE RATIO : Text ]]--
local sunfireRatio = {
  Display = {
    DisplayText = [[%c]],
    UpdateCustomTextOn = [[EveryFrame]],
    CustomFunction = function()
      if (displaySunRatio == true) then
        local Sun_pDamage = (1841 + 0.24 * SPNat) * DamageMultiplierNat
        local Sun_RatioPercent = (Sun_pDamage / Sun_sDamage) * 100

        if (Sun_RatioPercent >= 101) then
          local Sun_tDuration, Sun_tExpiry = select(6, UnitDebuff("target", "Sunfire", nil, "PLAYER"))
          local Sun_tClipPerSec = ((Sun_RatioPercent / 100 * Sun_tDuration) - Sun_tDuration)
          local Sun_tClipInterval = (Sun_tClipPerSec - (Sun_tClipPerSec % 2))
          local Sun_tRemaining = (Sun_tExpiry - GetTime())

          if (Sun_tRemaining <= Sun_tClipInterval) then
            return format("|cFFFF6900%d|r", Sun_RatioPercent)
          else
            return format("|cFF00FF00%d|r", Sun_RatioPercent)
          end
        else
          return format("|cFF777777%d|r", Sun_RatioPercent)
        end
      else
        return ''
      end
    end,
  },
  Trigger = {
    Type = [[Aura]],
    Auras = [[Sunfire]],
  },
  Actions = {
    OnShow = [[
      displaySunRatio = true
    ]],
    OnHide = [[
      displaySunRatio = false
    ]],
  },
}

--[[ MOONFIRE RATIO : Text ]]--
local moonfireRatio = {
  Display = {
    DisplayText = [[%c]],
    UpdateCustomTextOn = [[EveryFrame]],
    CustomFunction = function()
      if (displayMoonRatio == true) then
        local Moon_pDamage = (1841 + 0.24 * SPArc) * DamageMultiplierArc
        local Moon_RatioPercent = (Moon_pDamage / Moon_sDamage) * 100
        if (Moon_RatioPercent >= 101) then
          local Moon_tDuration, Moon_tExpiry = select(6, UnitDebuff("target", "Moonfire", nil, "PLAYER"))
          local Moon_tClipPerSec = ((Moon_RatioPercent / 100 * Moon_tDuration) - Moon_tDuration)
          local Moon_tClipInterval = (Moon_tClipPerSec - (Moon_tClipPerSec % 2))
          local Moon_tRemaining = (Moon_tExpiry - GetTime())

          if (Moon_tRemaining <= Moon_tClipInterval) then
            return format("%d", Moon_RatioPercent)
          else
            return format("%d", Moon_RatioPercent)
          end
        else
          return format("%d", Moon_RatioPercent)
        end
      else
        return ''
      end
    end,
  },
  Trigger = {
    Type = [[Aura]],
    Auras = [[Moonfire]],
  },
  Actions = {
    OnShow = [[
      displayMoonRatio = true
    ]],
    OnHide = [[
      displayMoonRatio = false
    ]],
  },
}

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
  applyAuras()
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


