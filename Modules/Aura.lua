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

SUB.defaults = {
  profile = {
    enabled = false,
    threshhold = 119,
  },
}

local SPID_MOONFIRE = 8921
local SPID_SUNFIRE = 93402

local FMT_GRAY = "|cFF777777%d|r" -- gray
local FMT_ORANGE = "|cFFFF6900%d|r" -- orange
local FMT_GREEN = "|cFF00FF00%d|r" -- green

local gFireData = {
  ["Moonfire"] = {
    spAltName = "Sunfire",
    spEclipse = "Eclipse (Lunar)",
    getBonusDmg = function()
      return GetSpellBonusDamage(7)
    end,
    getDmgMultiplier = function()
      local CritArc = (1 + GetSpellCritChance(7) / 100)
      local Mastery = GetMasteryEffect() / 100
      local Ticks = ceil(7 * UnitSpellHaste("player") / 100) / 7 + 1
      local EclipseArc = (UnitBuff("player", "Eclipse (Lunar)") and (1.15 + Mastery)) or 1
      local CelestialAlignment = (UnitBuff("player", "Celestial Alignment") and 1.15) or 1
      local Form = (UnitBuff("player", "Moonkin Form") and 1.15) or 1
      Form = (UnitBuff("player", "Incarnation: Chosen of Elune") and 1.4) or Form
      return EclipseArc * CelestialAlignment * Form * Ticks * CritArc
    end,
    getEffectiveDamage = function(this)
      return (1841 + 0.24 * GetSpellBonusDamage(7)) * this.getDmgMultiplier()
    end,
    getSnapDamage = function()
      return Moon_sDamage or 0
    end,
  },
  ["Sunfire"] = {
    spAltName = "Moonfire",
    spEclipse = "Eclipse (Solar)",
    getBonusDmg = function()
      return GetSpellBonusDamage(4)
    end,
    getDmgMultiplier = function()
      local CritNat = (1 + GetSpellCritChance(4) / 100)
      local Mastery = GetMasteryEffect() / 100
      local Ticks = ceil(7 * UnitSpellHaste("player") / 100) / 7 + 1
      local EclipseNat = (UnitBuff("player", "Eclipse (Solar)") and (1.15 + Mastery)) or 1
      local CelestialAlignment = (UnitBuff("player", "Celestial Alignment") and 1.15) or 1
      local Form = (UnitBuff("player", "Moonkin Form") and 1.15) or 1
      Form = (UnitBuff("player", "Incarnation: Chosen of Elune") and 1.4) or Form
      return EclipseNat * CelestialAlignment * Form * Ticks * CritNat
    end,
    getEffectiveDamage = function(this)
      return (1841 + 0.24 * GetSpellBonusDamage(4)) * this.getDmgMultiplier()
    end,
    getSnapDamage = function()
      return Sun_sDamage or 0
    end,
  },
}

gFireData.cutoff = 119

_G.gFireData = gFireData

_G.gWtkFireRatioFunc = function(spName, untrigger)
  local ratioCutoff = gFireData.cutoff

  local spAltName = gFireData[spName].spAltName
  local spEclipse = gFireData[spName].spEclipse
  local sDamage = gFireData[spName].snapDamage or 0

  local formattxt = "|cFF777777%d|r" -- gray
  local ratioPercent = 1000

  if ((sDamage > 0) and UnitDebuff("target", spName, nil, "PLAYER")) then
    local pDamage = gFireData[spName]:getEffectiveDamage()
    ratioPercent = (pDamage / sDamage) * 100
  end

  local retval = untrigger

  if (ratioPercent >= ratioCutoff) then
    formattxt = "|cFF00FF00%d|r" -- green
    if (UnitDebuff("target", spAltName, nil, "PLAYER") or (not UnitBuff("player", spEclipse))) then
      retval = not untrigger
    end
  end

  local ratioText = ""
  if (ratioPercent < 1000) then
    ratioText = format(formattxt, ratioPercent)
  end
  gFireData[spName].ratioPercent = ratioPercent
  gFireData[spName].ratioText = ratioText
  return retval, ratioPercent, ratioText
end

function SUB:COMBAT_LOG_EVENT_UNFILTERED(...)
  local _, event, _, source, _, _, _, destination, _, _, _, spell, _, _, _, _, _, _, _, _, _ = ...
  if (source == UnitGUID("player") and destination == UnitGUID("target") and event == "SPELL_CAST_SUCCESS") then
    if (spell == 8921) then
      gFireData["Moonfire"].snapDamage = gFireData["Moonfire"]:getEffectiveDamage()
      if ((UnitBuff("player", "Celestial Alignment"))) then
        gFireData["Sunfire"].snapDamage = gFireData["Sunfire"]:getEffectiveDamage()
      end
    elseif (spell == 93402) then
      gFireData["Sunfire"].snapDamage = gFireData["Sunfire"]:getEffectiveDamage()
      if ((UnitBuff("player", "Celestial Alignment"))) then
        gFireData["Moonfire"].snapDamage = gFireData["Moonfire"]:getEffectiveDamage()
      end
    end
  end
end

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

function SUB:OnEnable()
  self:Printd("OnEnable")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:ApplySettings()
end

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


