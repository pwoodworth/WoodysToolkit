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

SUB.adata = {
  ["lunar"] = { -- arcane
    DamageMultiplier = 1,
    sDamage = 0,
    SPStd = 0,
    ratio = 0,
    DotName = "Moonfire",
    DotId = 8921,
    EclipseName = "Eclipse (Lunar)",
    other = "solar",
  },
  ["solar"] = { -- natural
    DamageMultiplier = 1,
    sDamage = 0,
    SPStd = 0,
    ratio = 0,
    DotName = "Sunfire",
    DotId = 93402,
    EclipseName = "Eclipse (Solar)",
    other = "lunar",
  }
}

SUB.bdata[8921] = SUB.adata["lunar"]
SUB.bdata[93402] = SUB.adata["solar"]

function SUB:CalcStdVals()
  self.adata.solar.SPStd, self.adata.lunar.SPStd = GetSpellBonusDamage(4), GetSpellBonusDamage(7)
  local CritNat, CritArc = (1 + GetSpellCritChance(4) / 100), (1 + GetSpellCritChance(7) / 100)
  local Mastery = GetMasteryEffect() / 100
  local Ticks = ceil(7 * UnitSpellHaste("player") / 100) / 7 + 1
  local EclipseArc = (UnitBuff("player", "Eclipse (Lunar)") and (1.15 + Mastery)) or 1
  local EclipseNat = (UnitBuff("player", "Eclipse (Solar)") and (1.15 + Mastery)) or 1
  local CelestialAlignment = (UnitBuff("player", "Celestial Alignment") and 1.15) or 1
  local Form = (UnitBuff("player", "Moonkin Form") and 1.15) or 1
  Form = (UnitBuff("player", "Incarnation: Chosen of Elune") and 1.4) or Form
  self.adata.lunar.DamageMultiplier = EclipseArc * CelestialAlignment * Form * Ticks * CritArc
  self.adata.solar.DamageMultiplier = EclipseNat * CelestialAlignment * Form * Ticks * CritNat
end

function SUB:COMBAT_LOG_EVENT_UNFILTERED(...)
  local _, event, _, source, _, _, _, destination, _, _, _, spell, _, _, _, _, _, _, _, _, _ = ...
  if (source == UnitGUID("player") and destination == UnitGUID("target") and event == "SPELL_CAST_SUCCESS") then
    local dotData = self.bdata[spell]
    if (dotData) then
      self:CalcStdVals()
      dotData.sDamage = (1841 + 0.24 * dotData.SPStd) * dotData.DamageMultiplier
      if UnitBuff("player", "Celestial Alignment") then
        local thatDot = self.adata[dotData.other]
        thatDot.sDamage = (1841 + 0.24 * thatDot.SPStd) * thatDot.DamageMultiplier
      end
    end
  end
end

function SUB:CalcRatios(dotType)
  self:CalcStdVals()
  local dotData = self.adata[dotType]

  local name, _, _, _, _, tDuration, tExpiry = UnitDebuff("target", dotData.DotName, nil, "PLAYER")
  if name then
    local pDamage = (1841 + 0.24 * dotData.SPStd) * dotData.DamageMultiplier
    dotData.ratio = (pDamage / dotData.sDamage) * 100
  else
    dotData.ratio = 999
  end

  local needIt = true
  if (dotData.ratio >= data.threshhold) then
    if (self.adata[dotData.other].ratio >= data.threshhold) and UnitBuff("player", dotData.EclipseName) then
      needIt = false
    end
  else
    needIt = false
  end
  return needIt, dotData.ratio, format("|cFF00FF00%d|r", dotData.ratio)
end

function SUB:Moonfire()
  local dotType = "lunar"
  local showIt, ratio, dotTxt = self:CalcRations(dotType)
  return showIt, dotTxt
end

function SUB:GetSunfire()
  local dotType = "solar"
  local showIt, ratio, dotTxt = self:CalcRations(dotType)
  return showIt, dotTxt
end

function SUB:FormatRatioText(dotName, pDamage, sDamage)
  local FMT_GRAY = "|cFF777777%d|r" -- gray
  local FMT_ORANGE = "|cFFFF6900%d|r" -- orange
  local FMT_GREEN = "|cFF00FF00%d|r" -- green

  local name, _, _, _, _, tDuration, tExpiry = UnitDebuff("target", dotName, nil, "PLAYER")

  if name then
    local ratioPercent = (pDamage / sDamage) * 100
    local tClipPerSec = ((ratioPercent / 100 * tDuration) - tDuration)
    local tClipInterval = (tClipPerSec - (tClipPerSec % 2))
    local tRemaining = (tExpiry - GetTime())
    if (ratioPercent >= data.threshhold) then
      if (tRemaining <= tClipInterval) then
        return format(FMT_ORANGE, ratioPercent)
      else
        return format(FMT_GREEN, ratioPercent)
      end
    end
  end
  return format(FMT_GRAY, ratioPercent)
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


